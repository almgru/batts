local func = require('func')

describe('func', function()
    describe('map', function()
        it('maps elements in a table', function()
            local expected = { 2, 4, 6, 8, 10 }
            local actual = func.map({ 1, 2, 3, 4, 5 }, function(el) return el * 2 end)

            assert.are.same(expected, actual)
        end)
    end)

    describe('reduce', function()
        it('it incrementally folds or accumulates a table into a single value or object', function()
            local sum = func.reduce({ 1, 2, 3, 4, 5 }, 0, function(acc, value) return acc + value end)
            assert.is.equal(15, sum)
        end)
    end)
end)
