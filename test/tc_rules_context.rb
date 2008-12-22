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

class TestContext < Test::Unit::TestCase
  include Rules
  
  def setup
    @engine = Engine.new_with_models([File.join(File.dirname(__FILE__), 'tc_rules_model.rules')])
    @c = Context.new(@engine, 'list', 'Post')
    @cfoo = Context.new(@engine, 'list', 'Post', :foo => 'bar')
    @ctask = Context.new(@engine, 'list', 'Post', :task => 'edit')
  end
  
  def test_context_required_keys
    assert_equal('list', @c.task)
    assert_equal('Post', @c.entity)
    assert_equal('edit', @ctask.task)
  end
  
  def test_context_key_access
    assert_equal('list', @c[:task])
    @c[:task] = 'edit'
    assert_equal('edit', @c[:task])
    assert_equal('edit', @c.task)
    
    # Context converts all keys to symbols
    @c["task"] = 'inspect'
    assert_equal('inspect', @c[:task])
    assert_equal('inspect', @c["task"])
    
    # Context returns nil for unknown keys
    assert_equal(nil, @c[:foo])
    
    # Context can create keys using []=
    @c[:foo] = 'bar'
    assert_equal('bar', @c[:foo])
  end
  
  def test_context_missing_method
    assert_equal(nil, @c.foo)
    @c["foo"] = 'test'
    assert_equal('test', @c.foo)
    
    # foo key created at initialization via initial_keys hash
    assert_equal('bar', @cfoo.foo)
  end
  
  def test_anonymous_setting_keys
    @c.test_anonymous_setting_keys = 'blah'
    assert_equal('blah', @c.test_anonymous_setting_keys)
  end
end