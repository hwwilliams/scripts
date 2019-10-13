import sys

def ask(confirmation_prompt, default_answer_no=False):
    while True:
        answer = (input(confirmation_prompt).strip()).lower()
        if default_answer_no and answer == '' or answer.startswith('n'):
            return False
        elif answer == '' or answer.startswith('y'):
            return True
        elif answer == 'exit':
            terminate()
        else:
            print(f'{bcolors.YELLOW}Invalid Input: Please enter yes or no.{bcolors.RESET}')

def terminate():
    print('Exiting script.')
    sys.exit()
