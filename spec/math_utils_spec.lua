local math_utils = require('math_utils')

describe('math_utils', function()
   it('rounds numbers to whole numbers', function()
      assert.are.equal(5, math_utils.integer_round(5.1))
   end)

   it('rounds up when fraction part > 0.5', function()
      assert.are.equal(6, math_utils.integer_round(5.6))
   end)

   it('rounds up when fraction part == 0.5', function()
      assert.are.equal(6, math_utils.integer_round(5.5))
   end)

   it('rounds zero to zero', function()
      assert.are.equal(0, math_utils.integer_round(0.0))
   end)

   it('rounds negative numbers', function()
      assert.are.equal(-5, math_utils.integer_round(-5.1))
   end)

   it('rounds negative numbers down when fraction part > 0.5', function()
      assert.are.equal(-6, math_utils.integer_round(-5.6))
   end)

   it('rounds negative numbers down when fraction part == 0.5', function()
      assert.are.equal(-6, math_utils.integer_round(-5.5))
   end)
end)
