#!/usr/bin/env ruby

# Copyright (c) 2007-2008, Jim Roepcke
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of Jim Roepcke nor the names of its contributors
#       may be used to endorse or promote products derived from this software
#       without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# qualifier.rb is based on the file by the same name in TapKit 0.5.2
#
# == License
# TapKit is copyright (C) 2003-2004 SPICE OF LIFE.
# It is a free software distributed under the BSD license.
# 
# == Author
# SUZUKI Tetsuya <suzuki@spice-of-life.net>

require 'strscan'
require 'set'

def _raise_error( object, key ) #:nodoc:
  msg =  "This \"#{object.class}\" object does not have a method "
  msg << "\"#{key}\", nor an instance variable \"@#{key.sub(/=$/,'')}\"."
  raise UnknownKeyError, msg
end

def retrieve_value_for_keypath( object, keypath )
  paths = keypath.split '.'
  begin
    paths.each do |path|
      object = object.__send__ path.to_sym
    end
  rescue Exception => e
    _raise_error(object, path)
  end
  object
end

module Rules

  class QualifierParser

    class ParseError < StandardError; end #:nodoc:

    attr_reader :qualifier

    def initialize( format, bindings )
      # @debug_strs = debug_strs
      expanded   = _expand(format.dup, bindings)
      tokens     = _analyze expanded
      @qualifier = _parse tokens
    end

    private

    def _expand( format, bindings )
      num = 0
      replace = nil
      format.gsub!(/%%/, '%')
      format.gsub!(/(%s|%d|%f|%@|%K)/) do
        case $1
        when '%s' then replace = "'#{_escape(bindings[num])}'"
        when '%d' then replace = bindings[num].to_i
        when '%f' then replace = bindings[num].to_f
        when '%@' then replace = _convert bindings[num]
        when '%K'
          if String === bindings[num] then
            replace = bindings[num]
          else
            replace = _convert bindings[num]
          end
        end
        num += 1
        replace
      end
      # if @debug_strs
      #   print "\n\nformat: \n" + format.inspect
      # end
      format
    end

    def _escape( string )
      string.to_s.gsub(/'/) { "\\'" }
    end

    def _convert( object )
      case object
      when String    then "'#{_escape(object)}'"
      when Integer   then object.to_i
      when Float     then object.to_f
      when true      then 'true'
      when false     then 'false'
      when nil       then 'nil'
      # when Date      then "(Date)'#{object}'"
      # when Time      then "(Time)'#{object}'"
      else
        "(#{object.class})'#{_escape(object.to_s)}'"
      end
    end

    def _analyze( format )
      format    = "(#{format})"
      scanner   = StringScanner.new format
      qualifier = nil
      tokens    = []
      op_reg    = /\A(==|!=|>=|<=|>|<|=|like|cilike)/im

      until scanner.eos? do
        scanner.skip(/\A[\s]+/)

        if str = scanner.scan(/\A\([A-Z]([a-zA-Z0-9]*)\)'(([^'\\]|\\.)*)'/) then
          tokens << scanner[0]
        elsif str = scanner.scan(/\A\([A-Z]([a-zA-Z0-9]*)\)"(([^'\\]|\\.)*)"/) then
          tokens << scanner[0]
        elsif str = scanner.scan(/\A(\(|\))/) then
          tokens << str
        elsif str = scanner.scan(op_reg) then
          tokens << Qualifier.operator_symbol(str)
        elsif str = scanner.scan(/\A\d+\.\d+/) then
          tokens << str.to_f
        elsif str = scanner.scan(/\A\d+/) then
          tokens << str.to_i
        elsif scanner.match?(/\Atrue\W/) then
          scanner.scan(/\Atrue/)
          tokens << true
        elsif scanner.match?(/\Afalse\W/) then
          scanner.scan(/\Afalse/)
          tokens << false
        elsif scanner.match?(/\Anil\W/) then
          scanner.scan(/\Anil/)
          tokens << nil
        elsif str = scanner.scan(/\A'(([^'\\]|\\.)*)'/) then
          tokens << scanner[0]
        elsif str = scanner.scan(/\A"(([^"\\]|\\.)*)"/) then
          tokens << scanner[0]
        else
          str = scanner.scan(/\A[^\s\(\)]+/)
          tokens << str
        end
      end
      # if @debug_strs
      #   print "\n\ntokens:\n" + tokens.inspect
      # end

      tokens
    end

    def _parse( tokens )
      op_stack  = []
      out_stack = []
      op = left = right = q = nil

      reg_and = /\Aand\Z/mi
      reg_or  = /\Aor\Z/mi
      reg_not = /\Anot\Z/mi

      tokens.each do |token|
        case token
        when '('
          op_stack << token
        when ')'
          until op_stack.last == '(' do
            op    = op_stack.pop
            right = out_stack.pop
            left  = out_stack.pop

            case op
            when Symbol
              if right =~ /\A\(([A-Z][a-zA-Z0-9]*)\)'(([^'\\]|\\.)*)'/
                value = Object.__send__($1, $2)
                q = KeyValueQualifier.new(left, op, value).cached
              elsif right =~ /\A\(([A-Z][a-zA-Z0-9]*)\)"(([^'\\]|\\.)*)"/
                value = Object.__send__($1, $2)
                q = KeyValueQualifier.new(left, op, value).cached
              elsif right =~ /\A'(([^'\\]|\\.)*)'/ then
                q = KeyValueQualifier.new(left, op, $1).cached
              elsif right =~ /\A"(([^"\\]|\\.)*)"/ then
                q = KeyValueQualifier.new(left, op, $1).cached
              elsif (Numeric === right) or (right == true) or \
                (right == false) or right.nil? then
                q = KeyValueQualifier.new(left, op, right).cached
              else
                q = KeyComparisonQualifier.new(left, op, right).cached
              end
            when reg_and
              if AndQualifier === right then
                right.qualifiers.unshift left
                q = right
              else
                q = AndQualifier.new([left, right]).cached
              end
            when reg_or
              if OrQualifier === right then
                right.qualifiers.unshift left
                q = right
              else
                q = OrQualifier.new([left, right]).cached
              end
            when reg_not
              # puts "op_stack:  " + op_stack.to_s
              # puts "out_stack: " + out_stack.to_s
              # puts "op:        " + op.to_s
              # puts "right:     " + right.to_s
              # puts "rightclass:" + right.class.name
              # puts "left:      " + left.to_s
              # puts "left class:" + left.class.name
              
              q = NotQualifier.new(right).cached
            end
            out_stack << q
          end
          op_stack.pop      
        when reg_and
          op_stack << token
        when reg_or
          op_stack << token
        when reg_not
          out_stack << nil
          op_stack << token
        when Symbol
          op_stack << token
        else
          out_stack << token
        end
      end

      result = out_stack.pop
      unless out_stack.empty? and op_stack.empty? then
        raise ParseError, 'parse error'
      end

      result
    end
  end


  # == Format Strings
  #
  # %s:: String
  # %d:: Integer
  # %f:: Float
  # %@:: An arbitrary Object argument.
  # %K:: Treated as a key
  # %%:: Literal % character
  #
  class Qualifier
    module ComparisonSupport
      def compare( left, right, symbol )
        __send__(symbol, left, right)
      end

      def equal?( left, right )
        left == right
      end

      def not_equal?( left, right )
        left != right
      end

      def greater?( left, right )
        left > right
      end

      def greater_or_equal?( left, right )
        left >= right
      end

      def less?( left, right )
        left < right
      end

      def less_or_equal?( left, right )
        left <= right
      end

      def like?( left, right )
        regexp = _convert_operator_to_regexp right
        if left =~ regexp then
          true
        else
          false
        end
      end

      def ci_like?( left, right )
        regexp = _convert_operator_to_regexp(right, true)
        if left =~ regexp then
          true
        else
          false
        end
      end

      private

      # * - (.*)
      # ? - .
      # option - m, i
      def _convert_operator_to_regexp( string, ci = false )
        converted = string.gsub(/(\*|\?)/) do |matched|
          case matched
          when '*' then '(.*)'
          when '?' then '.'
          end
        end

        if ci == true then
          /\A#{converted}/mi
        else
          /\A#{converted}/m
        end
      end
    end

    class UnknownKeyError < StandardError; end #:nodoc:

    extend ComparisonSupport

    EQUAL            = :'equal?'
    NOT_EQUAL        = :'not_equal?'
    CONTAIN          = :'contain?'
    GREATER          = :'greater?'
    GREATER_OR_EQUAL = :'greater_or_equal?'
    LESS             = :'less?'
    LESS_OR_EQUAL    = :'less_or_equal?'
    LIKE             = :'like?'
    CI_LIKE          = :'ci_like?'

    class << self
      R_OPERATORS = ['=', '==', '!=', '<', '<=', '>', '>=']
      OPERATORS   = ['=', '==', '!=', '<', '<=', '>', '>=', 'like', 'cilike']

      def new_with_format( format, bindings = [] )
        key = format.to_s.intern
        if CACHE.has_key?(key)
          CACHE[key]
        else
          parser = QualifierParser.new(format, bindings) # , true && format.index("NOT"))
          parser.qualifier.cached
        end
      end

      alias format new_with_format

      # Creates an AndQualifier with KeyValueQualifiers.
      def new_to_match_all_values( values )
        qualifiers = []
        values.each do |key, value|
          qualifier = KeyValueQualifier.new(key, EQUAL, value).cached
          qualifiers << qualifier
        end
        AndQualifier.new(qualifiers).cached
      end

      def new_to_match_any_value( values )
        qualifiers = []
        values.each do |key, value|
          qualifier = KeyValueQualifier.new(key, EQUAL, value).cached
          qualifiers << qualifier
        end
        OrQualifier.new(qualifiers).cached
      end

      def operator_symbol( string )
        case string.upcase
        when '='      then EQUAL
        when '=='     then EQUAL
        when '!='     then NOT_EQUAL
        when '>'      then GREATER
        when '>='     then GREATER_OR_EQUAL
        when '<'      then LESS
        when '<='     then LESS_OR_EQUAL
        when 'CILIKE' then CI_LIKE
        when 'LIKE'   then LIKE
        end
      end

      def operator_string( operator )
        case operator
        when EQUAL            then '='
        when NOT_EQUAL        then '!='
        when GREATER          then '>'
        when GREATER_OR_EQUAL then '>='
        when LESS             then '<'
        when LESS_OR_EQUAL    then '<='
        when LIKE             then 'like'
        when CI_LIKE          then 'cilike'
        end
      end

      def operators
        OPERATORS
      end

      def relational_operators
        R_OPERATORS
      end

      def filter( objects, qualifier )
        filtered = []
        objects.each do |object|
          if qualifier.eval? object then
            filtered << object
          end
        end
        filtered
      end
    end

    def initialize
      @binding_keys = [] # unsupported
    end
    
    CACHE = {}
    def self.get_cache
      CACHE
    end
    
    def cached # TODO: improve this to support invalidating caches
      CACHE[to_s.intern] ||= self
    end
    
    def <=>(x)
      x.size<=>self.size
    end

    def size
      1
    end
    
    def qualifier_keys
      set = Set.new
      add_qualifier_keys set
      set
    end

    # abstract - subclasses must override it
    def add_qualifier_keys( set ); end

    def each_qualifier
      yield self
    end
    
    def walk
      each_qualifier do |q|
        yield q
      end
    end
    
    def reverse_symbol(symbol)
      case symbol
        when Qualifier::EQUAL            then Qualifier::NOT_EQUAL
        when Qualifier::NOT_EQUAL        then Qualifier::EQUAL
        when Qualifier::GREATER          then Qualifier::LESS_OR_EQUAL
        when Qualifier::GREATER_OR_EQUAL then Qualifier::LESS
        when Qualifier::LESS             then Qualifier::GREATER_OR_EQUAL
        when Qualifier::LESS_OR_EQUAL    then Qualifier::GREATER
        else                            raise "cannot reverse symbol " + symbol.to_s
      end
    end
    
    def positive()
      case self
      when NotQualifier
        q_inner = self.qualifier
        case q_inner
        when NotQualifier
          positive q_inner
        when AndQualifier
          OrQualifier.new( q_inner.qualifiers.collect { |x| NotQualifier.new(x).cached.positive() } ).cached
        when OrQualifier
          AndQualifier.new( q_inner.qualifiers.collect { |x| NotQualifier.new(x).cached.positive() } ).cached
        when KeyValueQualifier
          KeyValueQualifier.new(q_inner.key, reverse_symbol(q_inner.symbol), q_inner.value).cached
        when KeyComparisonQualifier
          KeyComparisonQualifier.new(q_inner.left, reverse_symbol(q_inner.symbol), q_inner.right).cached
        end
      when AndQualifier
        AndQualifier.new( self.qualifiers.collect { |x| x.positive() } ).cached
      when OrQualifier
        OrQualifier.new( self.qualifiers.collect { |x| x.positive() } ).cached
      else
        self
      end
    end

    # returns an array of arrays of qualifiers
    # this doesn't work, and I don't need it right now
    # so it goes bye-bye.  I think there's something wrong
    # with the creation of AndQualifiers, i suspect somewhere
    # a qualifier is being mutated illegaly.
=begin
    def dnf()
      case self
      when AndQualifier
        # get all the sequences of qualifier with which to permute
        options = self.qualifiers.collect { |q| q.dnf() }
        # for each permutation of the conjuncts, make an AndQualifier with those conjuncts
        permutations = options.rules_sequence
        list_of_and_qualifiers = permutations.collect do |perm|
          quals = []
          perm.each do |qual|
            case qual
            when AndQualifier
              quals += qual.qualifiers.collect { |q| Qualifier.new_with_format(q.to_s) }
            else
              quals << Qualifier.new_with_format(qual.to_s)
            end
          end
          AndQualifier.new( quals ).cached
        end
        list_of_and_qualifiers
        # so this AndQualifier turned into a list of equivalent AndQualifiers
      when OrQualifier
        options = []
        self.qualifiers.each do |q|
          options += q.dnf()
        end
        options
      else
        [self]
      end
    end
=end

    alias inspect to_s
  end

  class KeyValueQualifier < Qualifier
    attr_reader :key, :value, :symbol

    def initialize( key, symbol, value )
      @key = key
      @symbol = symbol
      @value = value
      super()
    end

    def add_qualifier_keys( set )
      set << @key
    end

    def ==( other )
      if KeyValueQualifier === other then
        if (@key == other.key) and (@symbol == other.symbol) and \
          (@value == other.value) then
          return true
        end
      end
      false
    end

    def eval?( object )
      keypath = @key.split '.'
      _compare_with_keypath(object, keypath)
    end

    def eval_in_context?( context )
      fl = context.cached_eval(self)
      if fl.nil? then
        fl = context.add_eval_to_cache(eval?(context), self)
      end
      fl
    end
    
    private


    def _compare_with_keypath( object, keypath )
      key = keypath.shift
      dest = retrieve_value_for_keypath(object, key)

      result = false

      if (Array === dest) \
        and (keypath.empty? == false)  then
        result = true
        dest.each do |to_many|
          if _compare_with_keypath(to_many, keypath) == false then
            result = false
          end
        end
      elsif keypath.empty? then
        result = Qualifier.compare(dest, @value, @symbol)
      else
        result = _compare_with_keypath(dest, keypath)
      end

      result
    end

    public

    def to_s
      op = Qualifier.operator_string @symbol
      if String === @value then
        value_s = "'#@value'"
      else
        value_s = @value
      end

      "(#@key #{op} #{value_s})"
    end
  end


  class KeyComparisonQualifier < Qualifier
    attr_reader :left, :symbol, :right

    def initialize( left, symbol, right )
      @left   = left
      @symbol = symbol
      @right  = right
      super()
    end

    def add_qualifier_keys( set )
      set << @left
      set << @right
    end

    def ==( other )
      if KeyComparisonQualifier === other then
        if (@left == other.left) and (@symbol == other.symbol) and \
          (@right == other.right) then
          return true
        end
      end
      false
    end

    def eval?( object )
      Qualifier.compare(retrieve_value_for_keypath(object, @left),
                        retrieve_value_for_keypath(object, @right),
                        @symbol)
    end

    def eval_in_context?( context )
      fl = context.cached_eval(self)
      if fl.nil? then
        fl = context.add_eval_to_cache(eval?(context), self)
      end
      fl
    end

    def to_s
      op = Qualifier.operator_string @symbol
      "(#@left #{op} #@right)"
    end
  end


  class AndQualifier < Qualifier
    attr_reader :qualifiers

    def initialize( qualifiers )
      @qualifiers = qualifiers
      @size = qualifiers.inject(1) { |sum, q| sum + q.size }
      super()
    end

    def each_qualifier
      each do |qualifier|
        yield qualifier
      end
    end
    
    def each
      qualifiers.each do |qualifier|
        yield qualifier
      end
    end

    def each_qualifier
      each do |qualifier|
        qualifier.each_qualifier do |q|
          yield q
        end
      end
      yield self
    end
    
    def size
      sizes = 0
      self.qualifiers.each do |q|
        sizes += q.size
      end
      1 + sizes
    end
    
    def add_qualifier_keys( set )
      @qualifiers.each do |qualifier|
        qualifier.add_qualifier_keys set
      end
    end

    def ==( other )
      if AndQualifier === other then
        if @qualifiers == other.qualifiers then
          return true
        end
      end
      false
    end

    def eval?( object )
      @qualifiers.each do |qualifier|
        unless qualifier.eval? object then
          return false
        end
      end
      true
    end

    def eval_in_context?( context )
      fl = context.cached_eval(self)
      if fl.nil? then
        @qualifiers.each do |qualifier|
          unless qualifier.eval_in_context? context then
            context.add_eval_to_cache(false, self)
            return false
          end
        end
        context.add_eval_to_cache(fl = true, self)
      end
      fl
    end

    def to_s
      str = '('
      @qualifiers.each do |q|
        str << q.to_s
        unless @qualifiers.last == q then
          str << " AND "
        end
      end
      str << ')'
      str
    end
  end


  class OrQualifier < Qualifier
    attr_reader :qualifiers
    attr_reader :size
    
    def initialize( qualifiers )
      @qualifiers = qualifiers
      @size = qualifiers.inject(1) { |sum, q| sum + q.size }
      super()
    end

    def each
      qualifiers.each do |qualifier|
        yield qualifier
      end
    end

    def each_qualifier
      each do |qualifier|
        qualifier.each_qualifier do |q|
          yield q
        end
      end
      yield self
    end

    def add_qualifier_keys( set )
      @qualifiers.each do |qualifier|
        qualifier.add_qualifier_keys set
      end
    end

    def ==( other )
      if OrQualifier === other then
        if @qualifiers == other.qualifiers then
          return true
        end
      end
      false
    end

    def eval?( object )
      @qualifiers.each do |qualifier|
        if qualifier.eval? object then
          return true
        end
      end
      false
    end

    def eval_in_context?( context )
      fl = context.cached_eval(self)
      if fl.nil? then
        @qualifiers.each do |qualifier|
          if qualifier.eval_in_context? context then
            context.add_eval_to_cache(true, self)
            return true
          end
        end
        context.add_eval_to_cache(fl = false, self)
      end
      fl
    end

    def to_s
      str = '('
      @qualifiers.each do |q|
        str << q.to_s
        unless @qualifiers.last == q then
          str << " OR "
        end
      end
      str << ')'
      str
    end
  end

  class NotQualifier < Qualifier
    attr_reader :qualifier
    attr_reader :size
    
    def initialize( qualifier )
      @qualifier = qualifier
      @size = 1 + qualifier.size
      super()
    end

    def each_qualifier
      yield qualifier
      yield self
    end

    def add_qualifier_keys( set )
      qualifier.add_qualifier_keys set
    end

    def ==( other )
      bool = false
      if NotQualifier === other then
        if @qualifier == other.qualifier then
          bool = true
        end
      end

      bool
    end

    def eval?( object )
      unless @qualifier.eval? object then
        true
      else
        false
      end
    end

    def eval_in_context?( context )
      fl = context.cached_eval(self)
      if fl.nil? then
        unless @qualifier.eval_in_context? context then
          context.add_eval_to_cache(true, self)
          return true
        else
          context.add_eval_to_cache(false, self)
          return false
        end
      end
      fl
    end

    def to_s
      "(NOT #{qualifier})"
    end
  end
end

# -------------------

# From: http://snippets.dzone.com/posts/show/3332
# From: http://www.rubyonrailsblog.com/articles/2006/08/31/permutations-in-ruby-can-be-fun (in the comments)
# Author: Brian Mitchell

class Array
  # The accumulation is a bit messy but it works ;-)
  def rules_sequence(i = 0, *a)
    return [a] if i == size
    self[i].map {|x|
      rules_sequence(i+1, *(a + [x]))
    }.inject([]) {|m, x| m + x}     # this has to be used instead of flatten so I can sequence something
                                    # like [[[4]]] -> [[[4]]] rather than -> [[4]]; ruby 1.9 has an option for flatten
  end
end
