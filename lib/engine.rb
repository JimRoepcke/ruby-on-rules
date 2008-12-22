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
  
  class Engine
    
    def self.new_with_models(models)
      engine = new
      for filename in models
        engine.load_model filename
      end
      engine
    end
    
    def initialize
      @keys = Hash.new { |hash, key| hash[key] = (Hash.new { |hash, key| hash[key] = [] }) }
    end
    
    # TODO: make this method thread-safe
    def load_model(filename)
      model = Model.load filename
      model.each do |rule|
        @keys[rule.rhs_key][rule.priority] << rule
      end
      @keys.each_value do |priorities_hash|
        priorities_hash.each_value do |list|
          list.sort! # FIXME: not thread-safe
        end
      end
    end
    
    def candidates(key, context)
      result = []
      root = @keys[key.to_sym]
      root.keys.sort.reverse.each do |priority|
        rules = root[priority]
        for rule in rules
          if rule.is_candidate_in_context? context then
            result << rule
            # TODO: consider an optimization where we break immediately here
          end
        end
        if not result.empty? then
          break
        end
      end
      result
    end
    
    def lookup(key, context)
      result = nil # TODO: see comment below, this default needs some thought
      rules = candidates(key, context)
      if rules.empty? then
        # no rule was found, what should we do?
        # TODO: find out what we should really do here with no candidates
        return nil
      else
        target = rules.first
        result = target.fire_in_context(context)
        # TODO: consider warning if there are still candidates
      end
      result
    end
    
  end # class Engine
  
end # model Rules
