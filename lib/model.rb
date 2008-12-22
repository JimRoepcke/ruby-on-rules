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

  class Model
    
    def initialize
      @rules = []
    end
  
    def lhs format
      @lhs = format
    end
    
    def key key
      @key = key
    end
    
    def val value
      @val = value
    end
    
    def ass assignment
      @ass = assignment
    end
    
    def pri priority
      @pri = priority
    end
    alias :priority :pri
    
    def self.load filename
      dsl = new
      dsl.instance_eval(File.read(filename), filename)
      dsl.rules
    end
  
    def rule(&options)
      if options
        @lhs = @key = @val = @ass = @pri = nil
        options.call
        @rules << Rule.new(@lhs, @key, @val, @ass, @pri)
      end
    end
  
    def rules
      @rules
    end
    
    # let people use more natural syntax if they want
    alias :left :lhs
    alias :left_hand_side :lhs
    alias :rhs_key :key
    alias :right_hand_side_key :key
    alias :value :val
    alias :rhs_value :val
    alias :right_hand_side_value :val
    alias :assignment :ass
    alias :assignment_class :ass
    
  end

end # module Rules