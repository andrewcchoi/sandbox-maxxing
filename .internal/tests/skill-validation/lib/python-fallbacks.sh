#!/bin/bash
# Python-based fallbacks for jq and bc

# jq replacement using Python
jq() {
    python3 -c '
import json
import sys

# Get arguments passed from bash
args = sys.argv[1:]

# Handle different jq patterns
if len(args) == 0:
    # Just validate JSON (jq empty)
    try:
        json.load(sys.stdin)
        sys.exit(0)
    except:
        sys.exit(1)

elif args[0] == "empty":
    # Validate JSON syntax
    try:
        # Check if a filename was provided
        if len(args) > 1:
            with open(args[1], "r") as f:
                json.load(f)
            sys.exit(0)
        else:
            json.load(sys.stdin)
            sys.exit(0)
    except Exception as e:
        print(f"JSON validation error: {e}", file=sys.stderr)
        sys.exit(1)

elif args[0] == "-r" and len(args) > 1:
    # Raw output mode
    pattern = args[1]

    # Read from file if provided
    if len(args) > 2:
        with open(args[2], "r") as f:
            data = json.load(f)
    else:
        data = json.load(sys.stdin)

    # Handle "paths | join(\".\")" pattern
    if "paths" in pattern and "join" in pattern:
        def get_paths(obj, prefix=""):
            paths = []
            if isinstance(obj, dict):
                for key, value in obj.items():
                    new_prefix = f"{prefix}.{key}" if prefix else key
                    paths.append(new_prefix)
                    if isinstance(value, (dict, list)):
                        paths.extend(get_paths(value, new_prefix))
            elif isinstance(obj, list):
                for i, value in enumerate(obj):
                    new_prefix = f"{prefix}[{i}]"
                    paths.append(new_prefix)
                    if isinstance(value, (dict, list)):
                        paths.extend(get_paths(value, new_prefix))
            return paths

        for path in get_paths(data):
            print(path)
        sys.exit(0)

elif args[0] == "-e":
    # Check if key exists
    pattern = args[1]

    # Read from file if provided
    if len(args) > 2:
        with open(args[2], "r") as f:
            data = json.load(f)
    else:
        data = json.load(sys.stdin)

    # Simple key check (e.g., .name, .workspaceFolder)
    key = pattern.lstrip(".")
    if key in data:
        print(json.dumps(data[key]))
        sys.exit(0)
    else:
        sys.exit(1)

else:
    # Default: just pretty print from stdin
    data = json.load(sys.stdin)
    print(json.dumps(data, indent=2))
    sys.exit(0)
' "$@"
}

# bc replacement using Python for safe arithmetic calculations only
bc() {
    python3 -c '
import sys
import re
import ast
import operator

# Safe arithmetic evaluator (no arbitrary code execution)
class SafeArithmeticEvaluator:
    # Allowed operations for arithmetic only
    operators = {
        ast.Add: operator.add,
        ast.Sub: operator.sub,
        ast.Mult: operator.mul,
        ast.Div: operator.truediv,
        ast.Mod: operator.mod,
        ast.Pow: operator.pow,
        ast.USub: operator.neg,
    }

    def evaluate(self, expr_str):
        """Safely evaluate arithmetic expression"""
        try:
            tree = ast.parse(expr_str, mode="eval")
            return self._eval_node(tree.body)
        except Exception as e:
            raise ValueError(f"Invalid expression: {e}")

    def _eval_node(self, node):
        if isinstance(node, ast.Num):
            return node.n
        elif isinstance(node, ast.Constant):  # Python 3.8+
            return node.value
        elif isinstance(node, ast.BinOp):
            left = self._eval_node(node.left)
            right = self._eval_node(node.right)
            op_func = self.operators.get(type(node.op))
            if op_func is None:
                raise ValueError(f"Unsupported operator: {type(node.op)}")
            return op_func(left, right)
        elif isinstance(node, ast.UnaryOp):
            operand = self._eval_node(node.operand)
            op_func = self.operators.get(type(node.op))
            if op_func is None:
                raise ValueError(f"Unsupported operator: {type(node.op)}")
            return op_func(operand)
        elif isinstance(node, ast.Compare):
            # Handle comparison operators
            left = self._eval_node(node.left)
            for op, comparator in zip(node.ops, node.comparators):
                right = self._eval_node(comparator)
                if isinstance(op, ast.Gt):
                    if not (left > right):
                        return 0
                elif isinstance(op, ast.GtE):
                    if not (left >= right):
                        return 0
                elif isinstance(op, ast.Lt):
                    if not (left < right):
                        return 0
                elif isinstance(op, ast.LtE):
                    if not (left <= right):
                        return 0
                elif isinstance(op, ast.Eq):
                    if not (left == right):
                        return 0
                left = right
            return 1
        else:
            raise ValueError(f"Unsupported node type: {type(node)}")

# Read expression from stdin or args
args = sys.argv[1:]
if len(args) > 0:
    if args[0] == "-l":
        # Ignore -l flag, just read from stdin
        expr = sys.stdin.read().strip()
    else:
        expr = " ".join(args)
else:
    expr = sys.stdin.read().strip()

# Handle scale directives
scale = 2
if "scale=" in expr:
    parts = expr.split(";")
    scale_match = re.search(r"scale=(\d+)", parts[0])
    scale = int(scale_match.group(1)) if scale_match else 2
    expr = parts[-1].strip()

try:
    evaluator = SafeArithmeticEvaluator()
    result = evaluator.evaluate(expr)

    if isinstance(result, float):
        print(f"{result:.{scale}f}")
    else:
        print(result)
    sys.exit(0 if result else 1)
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
' "$@"
}

# Export functions
export -f jq
export -f bc
