"""Every line of dialogue fits the 18-column text box, with an enemy's name
("Enemy " and 10 letters) or a 12-letter move or item name in it
(tools/text_lint.py)."""

import os
import subprocess
import sys
import unittest

from harness import REPO_ROOT


class TextFitTest(unittest.TestCase):
    def test_no_line_too_wide(self):
        out = subprocess.run([sys.executable, os.path.join("tools", "text_lint.py")], cwd=REPO_ROOT,
                             capture_output=True, text=True, check=True)
        self.assertEqual(out.stdout, "", "\n" + out.stdout)


if __name__ == "__main__":
    unittest.main()
