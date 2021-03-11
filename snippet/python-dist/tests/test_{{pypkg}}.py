import sys
import unittest

from {{pypkg}} import {{pypkg}}


class DistInfoTestCase(unittest.TestCase):

    def test_{{pypkg}}(self):
        """ тест функций """

        self.assertEqual(123, 123, '')



if __name__ == '__main__':
    unittest.main()
