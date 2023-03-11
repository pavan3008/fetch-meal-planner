# fetch-meal-planner

A native iOS app that allows users to browse recipes using the following API:
https://themealdb.com/api.php

There are 2 endpoints that app utilizes:
● https://themealdb.com/api/json/v1/1/filter.php?c=Dessert for fetching the list of meals in the
Dessert category.
● https://themealdb.com/api/json/v1/1/lookup.php?i=MEAL_ID for fetching the meal details by its
ID.

The user should be shown the list of meals in the Dessert category, sorted alphabetically.
When the user selects a meal, they should be taken to a detail view that includes:
● Meal name
● Instructions
● Ingredients/measurements
