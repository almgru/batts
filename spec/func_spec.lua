local func = require('func')

describe('func', function()
   describe('map', function()
      it('maps elements in a table', function()
         local expected = { 2, 4, 6, 8, 10 }
         local actual = func.map({ 1, 2, 3, 4, 5 }, function(el) return el * 2 end)

         assert.are.same(expected, actual)
      end)
   end)
end)
