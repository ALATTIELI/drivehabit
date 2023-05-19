# Drive Habit App

## Description
Drive Habit is a mobile app designed to help users improve their driving habits and promote safe driving practices. The app utilizes various technologies such as Flutter, Firebase, and MongoDB to provide users with features like driving session monitoring, logging, and grading.

## Prerequisites
Before running the app, make sure you have the following installed:
- Flutter SDK
- Firebase account and project setup
- MongoDB database (or use a cloud-based MongoDB service)

## Getting Started
1. Clone the repository to your local machine.
2. Install dependencies by running `flutter pub get`.
3. Set up the Firebase project and configure the necessary Firebase services (authentication, Firestore, etc.).
4. Create a .env file in the root directory of the project.
5. In the .env file, add the following environment variable:
   ```
   MONGO_URI=mongodb+srv://<username>:<password>@<cluster-url>/<database>
   ```
   Replace `<username>`, `<password>`, `<cluster-url>`, and `<database>` with your MongoDB connection details.
6. Save the .env file.

## Running the App
1. Connect your mobile device or start an emulator.
2. Run the app using the following command:
   ```
   flutter run
   ```
   This will build and run the app on your connected device/emulator.

## Usage
- Upon launching the app, users will be prompted to log in using their Google account.
- Once logged in, users can start a driving session to track their driving behavior.
- The app will collect location data and provide feedback on adherence to speed limits.
- Users can view their driving history and statistics in the Logs section.
- The Profile section allows users to manage their account and perform actions like logout and account deletion.

## Contributing
Contributions are welcome! If you have any suggestions or would like to contribute to the development of Drive Habit, please submit a pull request or open an issue.

## License
This project is licensed under the [MIT License](LICENSE).