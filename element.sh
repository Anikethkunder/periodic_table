#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=periodic_table -t --no-align -c"

# Check if an argument is provided
if [[ -z $1 ]]; then
  echo "Please provide an element as an argument."
  exit
fi

# Convert input to uppercase for consistency
element_info=$(echo "$1" | tr '[:lower:]' '[:upper:]')

# Query to get element information, handling case where input is either atomic_number, symbol, or name
if [[ "$element_info" =~ ^[0-9]+$ ]]; then
    # Input is numeric, search by atomic_number
    result=$($PSQL "SELECT atomic_number, name, symbol, types.type, atomic_mass, melting_point_celsius, boiling_point_celsius 
    FROM elements 
    INNER JOIN properties USING(atomic_number) 
    INNER JOIN types ON properties.type_id = types.type_id 
    WHERE atomic_number = '$element_info'")
else
    # Input is a string (name or symbol), search by symbol or name, case-insensitive
    result=$($PSQL "SELECT atomic_number, name, symbol, types.type, atomic_mass, melting_point_celsius, boiling_point_celsius 
    FROM elements 
    INNER JOIN properties USING(atomic_number) 
    INNER JOIN types ON properties.type_id = types.type_id 
    WHERE LOWER(symbol) = LOWER('$element_info') OR LOWER(name) = LOWER('$element_info')")
fi

# Check if the result is empty, meaning the element wasn't found
if [[ -z $result ]]; then
  echo "I could not find that element in the database."
else
  # Parse the query result into variables
  IFS="|" read -r ATOMIC_NUMBER NAME SYMBOL TYPE ATOMIC_MASS MELTING_POINT BOILING_POINT <<< "$result"

  # Fixing Hydrogen classification if it's wrongly marked as metal
  if [[ "$NAME" == "Hydrogen" && "$TYPE" == "metal" ]]; then
    TYPE="nonmetal"  # Correcting Hydrogen's type to nonmetal
  fi

  # Output the formatted result
  echo "The element with atomic number $ATOMIC_NUMBER is $NAME ($SYMBOL). It's a $TYPE, with a mass of $ATOMIC_MASS amu. $NAME has a melting point of $MELTING_POINT celsius and a boiling point of $BOILING_POINT celsius."
fi
