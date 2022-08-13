local stats = require('stats')

describe('stats', function()
   describe('mean', function()
      it('calculates the mean of elements in a table', function()
         assert.are.same(5, stats.mean({ 10, 0, 4, 6 }))
      end)
   end)

   describe('variance', function()
      it('calculates the variance of elements in a table', function()
         assert.is.equal(2 / 3, stats.variance({ 1, 2, 3 }, 2))
      end)
   end)

   describe('standard_deviation', function()
      it('calculates the standard deviation for elements in a table', function()
         assert.is.equal(0.5, stats.standard_deviation({ 1, 2, 1, 2 }))
      end)
   end)

   describe('z_scores', function()
      it('calculates the standard score for elements in a table', function()
         assert.are.same({ -1, -1, 1, 1 }, stats.z_scores({ 1, 1, 5, 5 }, 3, 2))
      end)
   end)

   describe('filter_out_outliers', function()
      it('removes outliers from a table based on z scores', function()
         local data = { -100, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 100 }
         local z_scores = {
            -3.0910568932221,
            -0.17493343876034,
            -0.14606092931022,
            -0.11718841986011,
            -0.088315910409989,
            -0.059443400959872,
            -0.030570891509756,
            -0.0016983820596389,
            0.027174127390478,
            0.056046636840594,
            0.084919146290711,
            0.11379165574083,
            0.14266416519094,
            0.17153667464106,
            0.20040918409118,
            0.22928169354129,
            2.6834449968012,
         }

         local expected = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 }
         local actual = stats.filter_out_outliers(data, z_scores)

         assert.are.same(expected, actual)
      end)
   end)
end)
