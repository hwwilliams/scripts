total_lambs = 1000000


def fib(num):
    a, b = 0, 1
    for i in range(0, num + 1):
        if (num - a) >= 0:
            num = num - a
            yield a
            a, b = b, a + b
        else:
            break


def stingy(total_lambs):
    payroll = list(fib(total_lambs))
    if payroll[0] == 0:
        payroll.pop(0)
    print(f'Stingy Payroll: {payroll}')
    print(f'Stingy Payroll Sum: {sum(payroll)}')
    return len(payroll)


def generous(total_lambs):
    payroll = [1]
    while True:
        if (sum(payroll) + payroll[-1] * 2) <= total_lambs:
            payroll.append(payroll[-1] * 2)
        else:
            break
    leftover_lambs = (total_lambs - sum(payroll))
    print(f'Leftover LAMBs: {leftover_lambs}')
    if (leftover_lambs >= sum(payroll[-2:])):
        payroll.append(leftover_lambs)
    print(f'Generous Payroll: {payroll}')
    print(f'Generous Payroll Sum: {sum(payroll)}')
    return len(payroll)

# def generous(total_lambs):
#   payroll = [1]
#   while True:
#     if (sum(payroll) + payroll[-1] * 2) <= total_lambs:
#       payroll.append(payroll[-1] * 2)
#     elif ((total_lambs - sum(payroll)) >= sum(payroll[-2:])):
#       print(f'Leftover LAMBs: {(total_lambs - sum(payroll))}')
#       payroll.append((total_lambs - sum(payroll)))
#     else:
#         break
#   print(f'Generous Payroll: {payroll}')
#   print(f'Generous Payroll Sum: {sum(payroll)}')
#   return len(payroll)


def solution(total_lambs):
    print(f'LAMBs: {total_lambs}')

    generous_len = generous(total_lambs)
    print(f'Generous Payroll Length: {generous_len}')

    stingy_len = stingy(total_lambs)
    print(f'Stingy Payroll Length: {stingy_len}')

    print(f'Solution: {stingy_len - generous_len}')


if __name__ == "__main__":
    solution(total_lambs)
