local date_utils = require('date_utils')

describe('date_utils', function()
   describe('get_hours_and_minutes', function()
      it('splits a number into hours and minutes', function()
         local actual_hours, actual_minutes = date_utils.get_hours_and_minutes(61)

         assert.is.equal(1, actual_hours)
         assert.is.equal(1, actual_minutes)
      end)
   end)
end)
