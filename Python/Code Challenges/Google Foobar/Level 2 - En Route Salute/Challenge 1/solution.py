def solution(s):
    salutes = 0

    origin_left = {}
    origin_right = {}

    for position, employee in enumerate(s):
        if employee == '>':
            origin_left[position] = employee
        elif employee == '<':
            origin_right[position] = employee

    if len(origin_left) > 0 and len(origin_right) > 0:
        for position_origin_left, employee_origin_left in origin_left.items():
            for position_origin_right, employee_origin_right in origin_right.items():
                if position_origin_left < position_origin_right:
                    salutes = salutes + 2

    return salutes
