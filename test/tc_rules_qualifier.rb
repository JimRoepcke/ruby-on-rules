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

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'rules'
require 'test/unit'

class TitleMock < Struct.new(:title); end
class ReleaseMock < Struct.new(:release); end
class BookMock < Struct.new(:title, :publisher); end
class PublisherMock < Struct.new(:name); end

class TestQualifier < Test::Unit::TestCase
  include Rules
  # operators

  def test_operators
    expected = ['=', '==', '!=', '<', '<=', '>', '>=', 'like', 'cilike']
    assert_equal(expected, Qualifier.operators)
  end

  def test_relational_operators
    expected = ['=', '==', '!=', '<', '<=', '>', '>=']
    assert_equal(expected, Qualifier.relational_operators)
  end

  def test_operator_symbol
    expected = { 'dummylike' => nil, '=' => Qualifier::EQUAL,
      '=='   => Qualifier::EQUAL,   '!='     => Qualifier::NOT_EQUAL, 
      '>'    => Qualifier::GREATER, '>='     => Qualifier::GREATER_OR_EQUAL,
      '<'    => Qualifier::LESS,    '<='     => Qualifier::LESS_OR_EQUAL,
      'like' => Qualifier::LIKE,    'cilike' => Qualifier::CI_LIKE }

    expected.each do |string, symbol|
      assert_equal(symbol, Qualifier.operator_symbol(string))
    end
  end

  def test_operator_string
    expected = { 'dummy' => nil,
      Qualifier::EQUAL   => '=' ,   Qualifier::NOT_EQUAL        => '!=',
      Qualifier::GREATER => '>',    Qualifier::GREATER_OR_EQUAL => '>=',
      Qualifier::LESS    => '<',    Qualifier::LESS_OR_EQUAL    => '<=',
      Qualifier::LIKE    => 'like', Qualifier::CI_LIKE          => 'cilike' }

    expected.each do |symbol, string|
      assert_equal(string, Qualifier.operator_string(symbol))
    end
  end


  # qualifier

  def test_new_to_match_all_values
    values    = {'title' => 'test', 'number' => 1}
    expected  = "((number = 1) AND (title = 'test'))"
    qualifier = Qualifier.new_to_match_all_values values

    assert_equal(expected, qualifier.to_s)
    assert_instance_of(AndQualifier, qualifier)
  end

  def test_new_to_match_any_value
    values    = {'title' => 'test', 'number' => 1}
    expected  = "((number = 1) OR (title = 'test'))"
    qualifier = Qualifier.new_to_match_any_value values

    assert_equal(expected, qualifier.to_s)
    assert_instance_of(OrQualifier, qualifier)
  end

  def test_new_with_format
    qualifier = Qualifier.new_with_format "title like '*'"
    assert_instance_of(KeyValueQualifier, qualifier)
  end


  # filter

  def test_filter_equal
    qualifier = Qualifier.format "title = 'test'"
    object1 = TitleMock.new 'test'
    object2 = TitleMock.new 'dummy'
    object3 = TitleMock.new 'test'
    array    = [object1, object2, object3]
    expected = [object1, object3]
    assert_equal(expected, Qualifier.filter(array, qualifier))
  end

  def test_filter_not_equal
    qualifier = Qualifier.format "title != 'test'"
    object1 = TitleMock.new 'test'
    object2 = TitleMock.new 'dummy'
    object3 = TitleMock.new 'test'
    array    = [object1, object2, object3]
    expected = [object2]
    assert_equal(expected, Qualifier.filter(array, qualifier))
  end

  def test_filter_greater
    qualifier = Qualifier.format "release > 50"
    object1 = ReleaseMock.new 10
    object2 = ReleaseMock.new 50
    object3 = ReleaseMock.new 100
    array    = [object1, object2, object3]
    expected = [object3]
    assert_equal(expected, Qualifier.filter(array, qualifier))
  end

  def test_filter_greater_or_equal
    qualifier = Qualifier.format "release >= 50"
    object1 = ReleaseMock.new 10
    object2 = ReleaseMock.new 50
    object3 = ReleaseMock.new 100
    array    = [object1, object2, object3]
    expected = [object2, object3]
    assert_equal(expected, Qualifier.filter(array, qualifier))
  end

  def test_filter_less
    qualifier = Qualifier.format "release < 50"
    object1 = ReleaseMock.new 10
    object2 = ReleaseMock.new 50
    object3 = ReleaseMock.new 100
    array    = [object1, object2, object3]
    expected = [object1]
    assert_equal(expected, Qualifier.filter(array, qualifier))
  end

  def test_filter_less_or_equal
    qualifier = Qualifier.format "release <= 50"
    object1 = ReleaseMock.new 10
    object2 = ReleaseMock.new 50
    object3 = ReleaseMock.new 100
    array    = [object1, object2, object3]
    expected = [object1, object2]
    assert_equal(expected, Qualifier.filter(array, qualifier))
  end

  def test_filter_like
    qualifier = Qualifier.format "title like 'a*'"
    object1 = TitleMock.new 'abcde'
    object2 = TitleMock.new 'bcdea'
    object3 = TitleMock.new 'ABCDE'
    array    = [object1, object2, object3]
    expected = [object1]
    assert_equal(expected, Qualifier.filter(array, qualifier))
  end

  def test_filter_cilike
    qualifier = Qualifier.format "title cilike 'a*'"
    object1 = TitleMock.new 'abcde'
    object2 = TitleMock.new 'bcdea'
    object3 = TitleMock.new 'ABCDE'
    array    = [object1, object2, object3]
    expected = [object1, object3]
    assert_equal(expected, Qualifier.filter(array, qualifier))
  end



  # validate

  def test_qualifier_keys
    qualifier = Qualifier.new
    assert qualifier.qualifier_keys.empty?
  end

  # format

  def test_parser_for_literals
    left = "title like"
    tokens = { "'*'" => String, '"*"' => String, '100' => Fixnum, '0.1' => Float,
      'true' => TrueClass, 'false' => FalseClass, 'nil' => NilClass,
      'true_dummy' => String, "(Integer)'1'" => Fixnum }

    tokens.each do |right, expected|
      format = "#{left} #{right}"
      q = Qualifier.new_with_format format

      case q
      when KeyValueQualifier
        # p "right: " + right
        # p "q.value: " + q.value
        assert_instance_of(expected, q.value)
      when KeyComparisonQualifier
        assert_instance_of(expected, q.right)
      end
    end
  end

  def test_parser_for_operator
    operators = {
      '='    => Qualifier::EQUAL,
      '=='   => Qualifier::EQUAL,   '!='     => Qualifier::NOT_EQUAL, 
      '>'    => Qualifier::GREATER, '>='     => Qualifier::GREATER_OR_EQUAL,
      '<'    => Qualifier::LESS,    '<='     => Qualifier::LESS_OR_EQUAL,
      'like' => Qualifier::LIKE,    'cilike' => Qualifier::CI_LIKE }

    operators.each do |operator, expected|
      format = "title #{operator} '*'"
      q = Qualifier.new_with_format format

      assert_equal(expected, q.symbol)
    end
  end

  # %s, %d, %f, %@, %K, %%
  def test_parser_for_format_strings
    # bindings, convert
    tests = [
      {:convert => '%s', :bindings => 'test',  :expected => 'test', :key => false},
      {:convert => '%s', :bindings => '100',   :expected => '100',  :key => false},
      {:convert => '%s', :bindings => "'",     :expected => "\\'",  :key => false},
      {:convert => '%d', :bindings => '100',   :expected => 100,    :key => false},
      {:convert => '%d', :bindings => 100,     :expected => 100,    :key => false},
      {:convert => '%f', :bindings => '0.1',   :expected => 0.1,    :key => false},
      {:convert => '%f', :bindings => 0.1,     :expected => 0.1,    :key => false},
      {:convert => '%@', :bindings => 'test',  :expected => 'test', :key => false},
      {:convert => '%@', :bindings => "'",     :expected => "\\'",  :key => false},
      {:convert => '%@', :bindings => 100,     :expected => 100,    :key => false},
      {:convert => '%@', :bindings => 0.1,     :expected => 0.1,    :key => false},
      {:convert => '%@', :bindings => true,    :expected => true,   :key => false},
      {:convert => '%@', :bindings => false,   :expected => false,  :key => false},
      {:convert => '%@', :bindings => nil,     :expected => nil,    :key => false},
      {:convert => '%K', :bindings => 'test',  :expected => 'test', :key => true},
      {:convert => '%K', :bindings => 'k.p',   :expected => 'k.p',  :key => true},
      {:convert => '%K', :bindings => 100,     :expected => 100,    :key => false},
      {:convert => '%K', :bindings => 0.1,     :expected => 0.1,    :key => false},
      {:convert => '%K', :bindings => true,    :expected => true,   :key => false},
      {:convert => '%K', :bindings => false,   :expected => false,  :key => false},
      {:convert => '%K', :bindings => nil,     :expected => nil,    :key => false},
      {:convert => "'%%'", :bindings => 'dummy', :expected => '%',  :key => false}
    ]

    tests.each do |test|
      format = "title like #{test[:convert]}"
      qualifier = Qualifier.new_with_format(format, [test[:bindings]])

      if test[:key] == true then
        assert_instance_of(KeyComparisonQualifier, qualifier)
        assert_equal(test[:expected], qualifier.right)
      else
        assert_instance_of(KeyValueQualifier, qualifier)
        assert_equal(test[:expected], qualifier.value)
      end
    end
  end

  def test_parser_for_key_value
    expected_format = "(title like '*')"
    expected_qualifier = KeyValueQualifier.new('title', Qualifier::LIKE, '*')
    qualifier = Qualifier.new_with_format expected_format

    assert_equal(expected_qualifier, qualifier)
    assert_equal(expected_format, qualifier.to_s)
  end

  def test_parser_for_key_comparison
    expected_format = "(salary > manager.salary)"
    expected_qualifier = KeyComparisonQualifier.new( \
      'salary', Qualifier::GREATER, 'manager.salary')
    qualifier = Qualifier.new_with_format expected_format

    assert_equal(expected_qualifier, qualifier)
    assert_equal(expected_format, qualifier.to_s)
  end

  def test_parser_for_and
    expected_format = "((title like '*') AND (name = 'John'))"
    keyvalue1 = KeyValueQualifier.new('title', Qualifier::LIKE, '*')
    keyvalue2 = KeyValueQualifier.new('name', Qualifier::EQUAL, 'John')
    expected_qualifier = AndQualifier.new [keyvalue1, keyvalue2]
    qualifier = Qualifier.new_with_format expected_format

    assert_equal(expected_qualifier, qualifier)
    assert_equal(expected_format, qualifier.to_s)
  end

  def test_parser_for_and_2
    expected_format = "((title like '*') AND (NOT (foo > 'bar')))"
    keyvalue1 = KeyValueQualifier.new('title', Qualifier::LIKE, '*')
    keyvalue2 = NotQualifier.new(KeyValueQualifier.new('foo', Qualifier::GREATER, 'bar'))
    expected_qualifier = AndQualifier.new [keyvalue1, keyvalue2]
    qualifier = Qualifier.new_with_format expected_format

    assert_equal(expected_qualifier, qualifier)
    assert_equal(expected_format, qualifier.to_s)
  end

  def test_parser_for_and_3
    expected_format = "((NOT (foo > 'bar')) AND (title like '*'))"
    keyvalue1 = NotQualifier.new(KeyValueQualifier.new('foo', Qualifier::GREATER, 'bar'))
    keyvalue2 = KeyValueQualifier.new('title', Qualifier::LIKE, '*')
    expected_qualifier = AndQualifier.new [keyvalue1, keyvalue2]
    qualifier = Qualifier.new_with_format expected_format

    assert_equal(expected_qualifier, qualifier)
    assert_equal(expected_format, qualifier.to_s)
  end


  def test_parser_for_or
    expected_format = "((title like '*') OR (name = 'John'))"
    keyvalue1 = KeyValueQualifier.new('title', Qualifier::LIKE, '*')
    keyvalue2 = KeyValueQualifier.new('name', Qualifier::EQUAL, 'John')
    expected_qualifier = OrQualifier.new [keyvalue1, keyvalue2]
    qualifier = Qualifier.new_with_format expected_format

    assert_equal(expected_qualifier, qualifier)
    assert_equal(expected_format, qualifier.to_s)
  end

  def test_parser_for_not
    expected_format = "(NOT ((title like '*') AND (name = 'John')))"
    keyvalue1 = KeyValueQualifier.new('title', Qualifier::LIKE, '*')
    keyvalue2 = KeyValueQualifier.new('name', Qualifier::EQUAL, 'John')
    and_qualifier = AndQualifier.new [keyvalue1, keyvalue2]
    expected_qualifier = NotQualifier.new and_qualifier
    qualifier = Qualifier.new_with_format expected_format

    assert_equal(expected_qualifier, qualifier)
    assert_equal(expected_format, qualifier.to_s)
  end

end


# equal, to_s, eval?, add_qualifier_keys
class TestKeyValueQualifier < Test::Unit::TestCase
  include Rules

  def setup
    @qualifier = KeyValueQualifier.new('key', Qualifier::EQUAL, 'value')
  end

  def test_qualifier_keys
    expected = Set.new ['key']

    assert_equal(expected, @qualifier.qualifier_keys)
  end

  def test_equal
    qualifier1 = KeyValueQualifier.new('key', Qualifier::EQUAL, 'value')
    qualifier2 = KeyValueQualifier.new('key', Qualifier::EQUAL, 'value')

    assert_equal(qualifier1, qualifier2)
  end

  def test_eval?
    object    = TitleMock.new 'abcde'
    qualifier = Qualifier.format "title like 'ab*'"

    assert qualifier.eval?(object)

    object.title = 'cde'
    assert_equal(false, qualifier.eval?(object))
  end

  def test_to_s
    expected = "(key = 'value')"

    assert_equal(expected, @qualifier.to_s)
  end

end


class TestKeyComparisonQualifier < Test::Unit::TestCase
  include Rules

  def setup
    @qualifier = KeyComparisonQualifier.new('left', Qualifier::EQUAL, 'right.path')
  end

  def test_qualifier_keys
    expected = Set.new ['left', 'right.path']

    assert_equal(expected, @qualifier.qualifier_keys)
  end

  def test_equal
    qualifier1 = KeyComparisonQualifier.new('left', Qualifier::EQUAL, 'right.path')
    qualifier2 = KeyComparisonQualifier.new('left', Qualifier::EQUAL, 'right.path')

    assert_equal(qualifier1, qualifier2)
  end

  def test_eval?
    qualifier = Qualifier.format "title like publisher.name"

    publisher = PublisherMock.new 'test'
    book      = BookMock.new 'test', publisher

    assert qualifier.eval?(book)

    book.title = 'dummy'
    assert_equal(false, qualifier.eval?(book))
  end

  def test_to_s
    expected  = "(left = right.path)"

    assert_equal(expected, @qualifier.to_s)
  end
end


class TestAndQualifier < Test::Unit::TestCase
  include Rules

  def setup
    q1 = KeyValueQualifier.new('key1', Qualifier::EQUAL, 'value1')
    q2 = KeyValueQualifier.new('key2', Qualifier::EQUAL, 'value2')
    array = [q1, q2]
    @qualifier = AndQualifier.new array
  end

  def test_qualifier_keys
    expected = Set.new ['key1', 'key2']

    assert_equal(expected, @qualifier.qualifier_keys)
  end

  def test_equal
    keyvalue   = KeyValueQualifier.new('key', Qualifier::EQUAL, 'value')
    qualifier1 = AndQualifier.new [keyvalue]
    qualifier2 = AndQualifier.new [keyvalue]

    assert_equal(qualifier1, qualifier2)
  end

  def test_eval?
    qualifier = Qualifier.format "(title == 'test') and (publisher.name == 'dummy')"

    publisher = PublisherMock.new 'dummy'
    book      = BookMock.new 'test', publisher

    assert qualifier.eval?(book)

    publisher.name = 'failure'
    assert_equal(false, qualifier.eval?(book))
  end

  def test_to_s
    expected = "((key1 = 'value1') AND (key2 = 'value2'))"

    assert_equal(expected, @qualifier.to_s)
  end
end


class TestOrQualifier < Test::Unit::TestCase
  include Rules

  def setup
    q1 = KeyValueQualifier.new('key1', Qualifier::EQUAL, 'value1')
    q2 = KeyValueQualifier.new('key2', Qualifier::EQUAL, 'value2')
    array = [q1, q2]
    @qualifier = OrQualifier.new array
  end

  def test_qualifier_keys
    expected = Set.new ['key1', 'key2']

    assert_equal(expected, @qualifier.qualifier_keys)
  end

  def test_equal
    keyvalue   = KeyValueQualifier.new('key', Qualifier::EQUAL, 'value')
    qualifier1 = OrQualifier.new [keyvalue]
    qualifier2 = OrQualifier.new [keyvalue]

    assert_equal(qualifier1, qualifier2)
  end

  def test_eval?
    qualifier = Qualifier.format "(title == 'test') or (publisher.name == 'dummy')"

    publisher = PublisherMock.new 'dummy'
    book      = BookMock.new 'dummy', publisher

    assert qualifier.eval?(book)

    publisher.name = 'failure'
    assert_equal(false, qualifier.eval?(book))
  end

  def test_to_s
    expected = "((key1 = 'value1') OR (key2 = 'value2'))"

    assert_equal(expected, @qualifier.to_s)
  end
end


class TestNotQualifier < Test::Unit::TestCase
  include Rules

  def setup
    keyvalue   = KeyValueQualifier.new('key', Qualifier::EQUAL, 'value')
    @qualifier = NotQualifier.new keyvalue
  end

  def test_qualifier_keys
    expected = Set.new ['key']

    assert_equal(expected, @qualifier.qualifier_keys)
  end

  def test_equal
    keyvalue   = KeyValueQualifier.new('key', Qualifier::EQUAL, 'value')
    qualifier1 = NotQualifier.new keyvalue
    qualifier2 = NotQualifier.new keyvalue

    assert_equal(qualifier1, qualifier2)
  end

  def test_eval?
    object    = TitleMock.new 'cde'
    qualifier = Qualifier.format "not (title like 'ab*')"

    assert qualifier.eval?(object)

    object.title = 'abcde'
    assert_equal(false, qualifier.eval?(object))
  end

  def test_to_s
    expected  = "(NOT (key = 'value'))"

    assert_equal(expected, @qualifier.to_s)
  end
end


class TestQualifierComparisonSupport < Test::Unit::TestCase
  include Rules

  # ==, !=, >, >=, <, <=, like, cilike
  def test_compare
    tests = [ \
    {:symbol=>Qualifier::EQUAL, :left=>'yes', :right=>'yes', :expected=>true},
    {:symbol=>Qualifier::EQUAL, :left=>'yes', :right=>'no',   :expected=>false},
    {:symbol=>Qualifier::NOT_EQUAL, :left=>'yes', :right=>'no', :expected=>true},
    {:symbol=>Qualifier::NOT_EQUAL, :left=>'yes', :right=>'yes', :expected=>false},
    {:symbol=>Qualifier::GREATER, :left=>2, :right=>1, :expected=>true},
    {:symbol=>Qualifier::GREATER, :left=>2, :right=>2, :expected=>false},
    {:symbol=>Qualifier::GREATER_OR_EQUAL, :left=>2, :right=>1, :expected=>true},
    {:symbol=>Qualifier::GREATER_OR_EQUAL, :left=>2, :right=>2, :expected=>true},
    {:symbol=>Qualifier::GREATER_OR_EQUAL, :left=>1, :right=>2, :expected=>false},
    {:symbol=>Qualifier::LESS, :left=>1, :right=>2, :expected=>true},
    {:symbol=>Qualifier::LESS, :left=>1, :right=>1, :expected=>false},
    {:symbol=>Qualifier::LESS_OR_EQUAL, :left=>1, :right=>2, :expected=>true},
    {:symbol=>Qualifier::LESS_OR_EQUAL, :left=>1, :right=>1, :expected=>true},
    {:symbol=>Qualifier::LESS_OR_EQUAL, :left=>2, :right=>1, :expected=>false},
    {:symbol=>Qualifier::LIKE, :left=>'yes', :right=>'yes', :expected=>true},
    {:symbol=>Qualifier::LIKE, :left=>'yes', :right=>'y*', :expected=>true},
    {:symbol=>Qualifier::LIKE, :left=>'yes', :right=>'y?s', :expected=>true},
    {:symbol=>Qualifier::LIKE, :left=>'yes', :right=>'YES', :expected=>false},
    {:symbol=>Qualifier::CI_LIKE, :left=>'yes', :right=>'yes', :expected=>true},
    {:symbol=>Qualifier::CI_LIKE, :left=>'yes', :right=>'YES', :expected=>true},
    {:symbol=>Qualifier::CI_LIKE, :left=>'yes', :right=>'y*', :expected=>true},
    {:symbol=>Qualifier::CI_LIKE, :left=>'yes', :right=>'Y*', :expected=>true},
    {:symbol=>Qualifier::CI_LIKE, :left=>'yes', :right=>'y?s', :expected=>true},
    {:symbol=>Qualifier::CI_LIKE, :left=>'yes', :right=>'Y?s', :expected=>true},
    {:symbol=>Qualifier::CI_LIKE, :left=>'yes', :right=>'no', :expected=>false},
    ]

    tests.each do |test|
      assert_equal(test[:expected], \
        Qualifier.compare(test[:left], test[:right], test[:symbol]))
    end
  end
end

class TestQualifierWalking < Test::Unit::TestCase
  include Rules
  
  def test_walk
    expected_format = "((title like '*') AND (NOT (foo > 'bar')))"
    qualifier = Qualifier.new_with_format expected_format

    n = 0
    qualifier.walk do |q|
      n += 1
    end
    assert_equal(4, n)
  end
end

=begin
class TestQualifierDNF < Test::Unit::TestCase
  include Rules
  
  def test_dnf_simple
    expected_format = "(title like '*')"
    qualifier = Qualifier.new_with_format expected_format
    options = qualifier.dnf()
    assert_equal(1, options.size)
    assert_equal("(title like '*')", options[0].to_s)
  end
  
  def test_dnf_simple_and
    expected_format = "((title like '*') AND (foo > 'bar'))"
    qualifier = Qualifier.new_with_format expected_format
    options = qualifier.dnf()
    assert_equal(1, options.size)
    assert_equal(expected_format, options[0].to_s)
  end
  
  def test_dnf_simple_and_2
    expected_format = "((title like '*') AND ((foo > 'bar') AND (b = 'b')))"
    qualifier = Qualifier.new_with_format expected_format
    options = qualifier.dnf()
    assert_equal(1, options.size)
    assert_equal("((title like '*') AND (foo > 'bar') AND (b = 'b'))", options[0].to_s)
  end
  
  def test_dnf_simple_and_3
    expected_format = "((title like '*') AND ((foo > 'bar') AND ((a = 'a') AND (b = 'b'))))"
    qualifier = Qualifier.new_with_format expected_format
    options = qualifier.dnf()
    assert_equal(1, options.size)
    assert_equal("((title like '*') AND (foo > 'bar') AND (a = 'a') AND (b = 'b'))", options[0].to_s)
  end
  
  def test_dnf_simple_or
    expected_format = "((title like '*') OR (foo > 'bar'))"
    qualifier = Qualifier.new_with_format expected_format
    options = qualifier.dnf()
    assert_equal(2, options.size)
    assert_equal("(title like '*')", options[0].to_s)
    assert_equal("(foo > 'bar')", options[1].to_s)
  end
  
  def test_dnf_simple_and_with_or
    expected_format = "(((title like '*') OR (foo > 'bar')) AND (b = 'b'))"
    qualifier = Qualifier.new_with_format expected_format
    options = qualifier.dnf()
    assert_equal(2, options.size)
    assert_equal("((title like '*') AND (b = 'b'))", options[0].to_s)
    assert_equal("((foo > 'bar') AND (b = 'b'))", options[1].to_s)
  end
  
  def test_dnf_simple_and_with_or
    expected_format = "(((title like '*') OR (foo > 'bar')) AND ((a = 'a') OR (b = 'b')))"
    qualifier = Qualifier.new_with_format expected_format
    options = qualifier.dnf()
    assert_equal(4, options.size)
    assert_equal("((title like '*') AND (a = 'a'))", options[0].to_s)
    assert_equal("((title like '*') AND (b = 'b'))", options[1].to_s)
    assert_equal("((foo > 'bar') AND (a = 'a'))", options[2].to_s)
    assert_equal("((foo > 'bar') AND (b = 'b'))", options[3].to_s)
  end
end
=end
