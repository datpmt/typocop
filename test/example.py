def greet(name):
    print(f"Hello, {name}! Welcome to Python programming.")

def factorial(n):
    if n == 0 or n == 1:
        return 1
    else:
        result = 1
        for i in range(2, n + 1):
            result *= i
        return result

numbers = [5, 3, 8, 10]

for number in numbers:
    print(f"Factorial of {number} is: {factorial(number)}")

user_name = input("Enter your name: ")

greet(user_name)

age = int(input("Enter your age: "))
if age >= 18:
    print("You are elligible for an adult privilege.") # typo
    print("elligible.") # typo
    print("welcom.") # typo
else:
    print("You are underage, so no adult privileges for you.")
