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

module Rules

  # TODO: remove task and entity, refactor into a subclass ScaffoldContext
  class Context
    
    # if :task and :entity are in initial_keys they will
    # override the values of the task and entity arguments
    def initialize(engine, task, entity, initial_keys = {})
      @engine = engine
      # TODO: remove this and put it in ScaffoldContext
      # replace with:
      # @keys = {}.merge! initial_keys
      @keys = {:task => task, :entity => entity}
      @keys.merge! initial_keys
      invalidate_caches
    end
    
    def invalidate_caches
      @qualifier_evaluation_cache = {}
      @rule_lookup_cache = Hash.new { |hash, key| hash[key] = :RULES_CONTEXT_LOOKUP_CACHE_MISS }
    end
    
    # optimization for required key
    # TODO: remove this and put it in ScaffoldContext
    def task
      @keys[:task]
    end
    
    # optimization for required key
    # TODO: remove this and put it in ScaffoldContext
    def entity
      @keys[:entity]
    end
    
    # retrieve the value for a RHS key on this context or fall through
    # to method_missing which will do the right thing
    def [](key)
      send key.to_sym
    end
    
    # set a key in the internal hash and invalidate the cache
    # this lets you short-circuit the rules by hard-coding a value
    # for a RHS key
    def []=(key, value)
      invalidate_caches
      @keys[key.to_sym] = value
    end
    
    def cached_eval(qualifier)
      @qualifier_evaluation_cache[qualifier.object_id]
    end
    
    def add_eval_to_cache(fl, qualifier)
      @qualifier_evaluation_cache[qualifier.object_id] = fl
    end
    
    def cached_rule_lookup(key)
      @rule_lookup_cache[key]
    end
    
    def add_rule_lookup_to_cache(result, key)
      @rule_lookup_cache[key] = result
    end
    
    def method_missing(symbol, *args)
      # p "method_missing " + symbol.to_s
      if symbol.to_s[-1].chr == '='
        send :[]=, symbol.to_s[0..-2].to_sym, *args
      else
        if @keys.has_key? symbol
          return @keys[symbol]
        else
          result = cached_rule_lookup(symbol)
          # p "  cached lookup: " + result.to_s
          if result == :RULES_CONTEXT_LOOKUP_CACHE_MISS then
            # p "  missed cache looking for " + symbol.to_s
            result = add_rule_lookup_to_cache(@engine.lookup(symbol, self), symbol)
          end
          result # TODO: support a property on rules to optionally disallow caching the result
        end
      end
    end
        
  end # class Context
  
end # module Rules