# Eloisa R. Puducay
## INF233
## CTADMOBL Advance Mobile Programming
 
A Flutter Project that focuces on advance topics. Covering the web to mobile transactions
 
## Lab Activity Instance
### Lab Activity List
**Lab Activity 1 : Theme(Dark/Light Mode)**: setState is used for managing local widget state, such as the counter value, and only rebuilds the widget where the state changes. Provider manages shared application state, such as the app theme, by allowing multiple widgets to access and update the same data. In this code, setState is suitable for the counter, while Provider is better for the theme because it affects the entire application.

**Lab Activity 2**: In this activity, I learned how the model, service, and screen work together to display data from an API endpoint. The service connects to the API and gets the product data. The model organizes the data into the proper fields, such as the product name, price, description, and rating. After that, the screen uses the data from the service and displays it to the user through the product card.

I also learned that the screen does not need to handle everything by itself. The service is responsible for getting the data, while the model makes the data easier to use in the application. The screen only focuses on showing the information and interacting with the user. This makes the code more organized and easier to understand.

The new design pattern in this activity helped me separate the responsibilities of each part of the application. Instead of putting the API connection, data handling, and user interface in one place, they are separated into different files. I learned that this approach makes the project easier to maintain, debug, and improve when adding new features.

**Lab Activity 3**: In this activity, I learned how the cart model, service, and cart screen work together to display data from the API. The cart model is responsible for representing the cart information, while the service handles the API request and converts the response into data that the application can use. The CartScreen then displays the retrieved products, and when an item is selected, its product information is passed to the same detail_screen.dart. This updated design pattern makes the code more organized because the API logic, data model, and user interface have separate responsibilities.

I also learned how to use the getById approach in the Cart endpoint to retrieve a specific cart based on its ID or user ID. Instead of loading all cart records, the application can request only the cart needed and then display its products. This is useful when the application is intended to show one user's cart. Overall, the activity helped me understand how API endpoints, services, models, and screens are connected and how navigation can be reused to keep the application structure simpler and easier to maintain.

**Lab Activity 4**: In this activity, I learned how the user model, services, and screens work together to display data from the API. The User model is used to organize the user information such as the ID, username, email, name, gender, and image. The UserService handles the API login and saves the returned user data using SharedPreferences. The screen then uses the saved user data and the User model to display the information on the profile screen. The updated design pattern makes the code more organized because the API requests, data model, and UI are separated instead of putting everything in one screen.

I also learned that the saved user ID can be used to get the user's cart from the API. After the user logs in, the user ID is saved together with the other user information. The HomeScreen can get the saved user and pass user.id to the CartScreen. The CartScreen then passes this ID to the cart service, which uses it to call the cart endpoint for that specific user. This allows the application to display the correct cart based on the logged-in user instead of showing a general cart.