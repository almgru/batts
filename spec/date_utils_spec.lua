local date_utils = require('date_utils')

describe('date_utils', function()
   describe('get_hours_and_minutes', function()
      it('splits a number into hours and minutes', function()
         local actual_hours, actual_minutes = date_utils.get_hours_and_minutes(61)

         assert.is.equal(1, actual_hours)
         assert.is.equal(1, actual_minutes)
      end)
   end)

   describe('date_string_to_timestamp', function()
      it('converts a ISO date string to a unix timestamp', function()
         assert.is.equal(1577869200, date_utils.date_string_to_timestamp('2020-01-01 10:00:00'))
      end)
   end)
end)
