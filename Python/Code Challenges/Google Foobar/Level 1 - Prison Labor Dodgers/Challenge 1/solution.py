def solution(x, y):
    if len(y) > len(x):
        for number in y:
            if number not in x:
                return number

    elif len(y) < len(x):
        for number in x:
            if number not in y:
                return number
