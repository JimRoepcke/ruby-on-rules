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

  # a rule is (kind of sort of) like so:
  # def rhs_key
  #   if lhs
  #     return assignment(rhs_value)
  #   end
  # end
  
  class Rule
    
    attr_accessor :lhs_format, :qualifier, :rhs_key, :rhs_value, :assignment, :priority
    
    def initialize(lhs_format, rhs_key, rhs_value, assignment, priority)
      self.lhs_format = lhs_format
      self.qualifier = Qualifier.new_with_format(self.lhs_format) # Qualifier
      self.rhs_key = rhs_key.to_sym
      self.rhs_value = rhs_value
      self.assignment = assignment # TODO: support default assignment
      self.priority = priority
    end
    
    def <=>(x)
      self.qualifier <=> x.qualifier
    end
    
    def valid?
      # TODO: a rule isn't valid if the rhs key is used in the qualifier
      # self.qualifier and (not self.qualifier.qualifier_keys
    end
    
    def is_candidate_in_context?(context)
      # TODO: implement
      # evaluate the rule's qualifier
      qualifier.eval_in_context?(context)
    end
    
    def fire_in_context(context)
      # TODO: fire the rule using the assignment and
      #       rhs_value, return the result
      if (not self.assignment.nil?) and self.assignment.respond_to? :call
        self.assignment.call(self, context)
      else
        self.rhs_value
      end
    end
    
  end # class Rule
  
end # module Rules
