def print_star_triangle(rows):

    for i in range(rows):
        print(" " * (rows-i-1) + "*" * (2 * i + 1))  # Number of spaces + number of stars

rows = int(input("Enter the number of rows: "))

print_star_triangle(rows)
