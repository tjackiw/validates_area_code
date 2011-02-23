# Copyright (c) 2008 Thiago Jackiw
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'active_record'

module ValidatesAreaCode
  
  I18n.translate('activerecord.errors.messages')[:area_code] = "has an invalid area code."
  
  AREA_CODES = File.open(File.dirname(__FILE__) + "/data/area_codes"){|file| file.read} unless defined?(AREA_CODES)
  US_STATES  = File.open(File.dirname(__FILE__) + "/data/state_codes"){|f| f.read}.split("\n") unless defined?(US_STATES)
  TOLL_FREE  = "NANP area"
  
  module ClassMethods
    
    # As its name suggest, it validates the area code of an American phone number.
    # Usage:
    # 
    #   class User < ActiveRecord::Base
    #     validates_area_code :phone, :allow_toll_free => false, :format => {:with => /\d{3}-\d{3}-\d{4}/, :message => 'is invalid. Should be XXX-XXX-XXXX'}
    # 
      
    def validates_area_code(*attr_names)

      configuration = { :message => I18n.translate('activerecord.errors.messages')[:area_code], :format => {:with => nil, :message => 'has an invalid format.'}, :allow_toll_free => true }
      configuration.update(attr_names.pop) if attr_names.last.is_a?(Hash)
      
      raise(ArgumentError, "A regular expression must be supplied as the :with option of the configuration hash") unless configuration[:format][:with].is_a?(Regexp)

      validates_each(attr_names, configuration) do |record, attr_name, value|
        if configuration[:format][:with]
          record.errors.add(attr_name, configuration[:format][:message]) and next unless value.to_s =~ configuration[:format][:with]
        end
        record.errors.add(attr_name, configuration[:message]) unless area_code_exists?(value, configuration[:allow_toll_free])
      end
    end
    
    private
    def area_code_exists?(phone, allow_toll_free)
      return false unless phone
      phone = phone.gsub(/[^0-9-]/,"")
      unless (record = AREA_CODES.scan(/#{phone[0..2]}.*/).to_s).empty?
        US_STATES.push(TOLL_FREE) if allow_toll_free && !US_STATES.include?(TOLL_FREE)
        US_STATES.include?(record.split(',')[1])
      else
        return false
      end
    end
  end
  
  def self.included(base)
    base.extend ClassMethods
  end

end

ActiveRecord::Base.class_eval { include ValidatesAreaCode }
