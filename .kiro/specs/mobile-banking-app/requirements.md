# Requirements Document

## Introduction

FrostBank Mobile is a Flutter mobile banking application that runs fully offline against a mock repository layer. The application covers authentication, a gradient dashboard, account detail screens, card detail screens, transaction history with filtering, a send money flow, a four part Finance Hub (Savings, Crypto, Split Bills, Time Deposit), and a profile area with settings, security, and logout.

The application is built on a locked design system: a fixed token set transcribed from the brand palette, one radius scale, one accent, one typography scale (Outfit for display, Geist for user interface text, GeistMono for numerals), and full light and dark parity at WCAG AA contrast. State is managed with flutter_riverpod. Navigation uses go_router with an authentication redirect guard and a ShellRoute that hosts a floating pill bottom navigation bar.

Because the data layer is mocked, every figure is seed data. The specification therefore treats data authenticity, security posture for a mock application, motion restraint, interactive state completeness, accessibility, and copy discipline as first class requirements alongside the feature screens.

## Glossary

- **FrostBank_App**: The complete Flutter application, including its shell, routing, and theming.
- **Design_System**: The Flutter code layer that exposes color tokens, the radius scale, the spacing scale, the typography scale, and semantic token lookups for light and dark themes.
- **Theme_Controller**: The component that resolves the active brightness from system preference or from an explicit user override.
- **Motion_System**: The code layer that exposes named durations, named curves, and reduced motion resolution used by every animated widget.
- **Repository_Layer**: The set of abstract repository interfaces (accounts, cards, transactions, savings, crypto, split bills, time deposits, notifications, promotions, user profile) plus their mock implementations.
- **Mock_Data_Source**: The seeded in memory data source, with local persistence, that backs Repository_Layer.
- **Persistence_Store**: The on device key value store used to retain session state, user preferences, and mutations made during a session.
- **Auth_Service**: The component that validates credentials, creates and clears the session, and exposes authentication state.
- **Session_Guard**: The go_router redirect logic plus the lifecycle observer that enforces authenticated access and session timeout.
- **App_Lock**: The component that requires a PIN or biometric confirmation before the authenticated surface becomes visible.
- **Router**: The go_router configuration, including the ShellRoute that hosts the pill bottom navigation.
- **Shell_Nav**: The floating pill bottom navigation bar rendered by the ShellRoute, with the brand mark as the center item.
- **Splash_Screen**: The first screen shown at launch, containing the brand mark and a bounded load indicator.
- **Login_Screen**, **Register_Screen**, **Forgot_Password_Screen**: The three unauthenticated form screens.
- **Dashboard_Screen**: The authenticated home screen.
- **Balance_Privacy_Controller**: The component that toggles masking of monetary figures across the application.
- **Cards_Carousel**: The horizontal card thumbnail row on Dashboard_Screen, including the add card tile.
- **Card_Detail_Screen**: The screen showing a peeking card stack, a page dot indicator, the card balance, and a card info list.
- **Account_Detail_Screen**: The screen template used for the Savings Account, the Wallet, and the Crypto Wallet.
- **Transaction_History_Screen**: The screen listing all transactions with filtering.
- **Transaction_Filter**: The filter state applied to Transaction_History_Screen (type, date range, account, search text).
- **Transfer_Flow**: The multi step send money flow (recipient, amount, review, result).
- **Deposit_Flow**: The flow that adds funds to an account from a mock funding source.
- **QR_Scan_Screen**: The mock QR payment capture screen.
- **Finance_Hub**: The Dashboard_Screen section that links to Savings_Screen, Crypto_Screen, Split_Bills_Screen, and Time_Deposit_Screen.
- **Savings_Screen**, **Crypto_Screen**, **Split_Bills_Screen**, **Time_Deposit_Screen**: The four Finance Hub detail screens.
- **Notifications_Screen**: The screen listing notifications with read and unread state.
- **Promo_Carousel**: The tips and promotions image card row on Dashboard_Screen.
- **Profile_Screen**: The screen showing user information and entry points to settings, security, and logout.
- **Async_Surface**: Any widget region whose content is produced by an asynchronous Repository_Layer call.
- **Loading_Skeleton**: A non interactive placeholder whose block sizes and layout match the loaded content of its Async_Surface.
- **Empty_State**: A composed message plus a primary action that leads to populating the Async_Surface.
- **Error_State**: An inline message plus a retry control shown in place of failed Async_Surface content.
- **Reduced_Motion**: The condition where MediaQuery disableAnimations is true or MediaQuery accessibleNavigation is true.
- **UI_String**: Any text literal rendered to the screen, including labels, headings, body copy, button text, hints, error text, and semantic labels.

## Requirements

### Requirement 1: Design System Foundation

**User Story:** As a developer, I want a single locked source of design tokens, so that every screen stays visually consistent and no screen invents its own colors, radii, or type sizes.

#### Acceptance Criteria

1. THE Design_System SHALL expose the primary color tokens with the exact values Deep Navy #0B0D2B, Primary Purple #2B1E6B, Primary Blue #1565E0, Vibrant Blue #6A5CFF, and Sky Blue #BFD6FF.
2. THE Design_System SHALL expose three gradient tokens with the exact stops Primary #0B0D2B to #1565E0, Secondary #2B1E6B to #BFD6FF, and Card #1E1B4B to #00D4FF.
3. THE Design_System SHALL expose the neutral tokens with the exact values Text Primary #0F1123, Text Secondary #475569, Border #CBD5E1, Surface #F1F5F9, Background Light #F8FAFF, and Background #FFFFFF.
4. THE Design_System SHALL expose the semantic tokens with the exact values Success #22C55E, Info #1976D2, Warning #F59E0B, and Error #EF4444.
5. THE Design_System SHALL expose the interactive tokens with the exact values Primary #2B1E6B, Primary Hover #3C2A8C, Primary Active #6A5CFF, Secondary #EEF0FF, and Disabled #E2E8F0.
6. THE Design_System SHALL define exactly one radius scale with five named steps, and every rounded surface in FrostBank_App SHALL read its radius from that scale.
7. THE Design_System SHALL define exactly one accent token, and every highlight, active indicator, and focus ring in FrostBank_App SHALL resolve to that accent token.
8. THE Design_System SHALL register Outfit for display and headline text styles, Geist for user interface and body text styles, and GeistMono for monetary figures and card digits.
9. THE Design_System SHALL define a typography scale with named steps for display, headline, title, body, label, and numeric text, and every Text widget in FrostBank_App SHALL use a named step from that scale.
10. THE Design_System SHALL define a spacing scale based on a 4 logical pixel unit, and every padding and gap value in FrostBank_App SHALL be a multiple from that scale.
11. THE Design_System SHALL provide a light value and a dark value for every semantic token.
12. THE Design_System SHALL hold a contrast ratio of at least 4.5 to 1 for body text and at least 3.0 to 1 for text at 18 logical pixels or larger and for interactive boundaries, in both the light theme and the dark theme.
13. WHEN FrostBank_App starts, THE Theme_Controller SHALL resolve the active brightness from the operating system color scheme preference.
14. WHEN the user selects an explicit theme option in Profile_Screen settings, THE Theme_Controller SHALL apply the selected brightness and THE Persistence_Store SHALL retain that selection for the next launch.
15. IF a widget requests a color, radius, text style, or spacing value that is absent from Design_System, THEN THE Design_System SHALL fail the build with a named assertion that identifies the missing token.

### Requirement 2: Motion System

**User Story:** As a user, I want animation that explains what changed rather than decorates the screen, so that the application feels calm and stays usable when I turn animation off.

#### Acceptance Criteria

1. THE Motion_System SHALL expose a short duration band of 150 milliseconds to 200 milliseconds for press and state feedback, a medium duration band of 250 milliseconds to 350 milliseconds for screen and section transitions, and a long duration of at most 600 milliseconds reserved for the splash sequence and shared element hero transitions.
2. THE Motion_System SHALL expose a named curve set of at most three curves, and every animation in FrostBank_App SHALL use a curve from that set.
3. THE Motion_System SHALL restrict animated properties to opacity, translation, scale, and rotation.
4. WHERE an animation exists in FrostBank_App, THE source code SHALL carry a single sentence comment that states whether the animation serves hierarchy, storytelling, feedback, or state transition.
5. WHILE Reduced_Motion is active, THE Motion_System SHALL resolve every duration to zero and SHALL render the end state of every transition immediately.
6. THE Motion_System SHALL permit exactly one repeating animation in FrostBank_App, which is the Splash_Screen load indicator.
7. WHEN the Splash_Screen load sequence completes, THE Splash_Screen SHALL stop the load indicator animation and SHALL dispose its animation controller.
8. WHEN a route transition occurs inside Shell_Nav, THE Router SHALL animate the outgoing and incoming content using opacity and translation within the medium duration band.
9. IF an animation controller is created by a widget, THEN THE widget SHALL dispose that controller in its dispose method.

### Requirement 3: Interactive State Completeness

**User Story:** As a user, I want every data area to tell me clearly whether it is loading, empty, or broken, so that I never look at a blank region and guess.

#### Acceptance Criteria

1. WHILE an Async_Surface is awaiting its first Repository_Layer result, THE Async_Surface SHALL render a Loading_Skeleton whose block count, block heights, and layout match the loaded content.
2. THE Loading_Skeleton SHALL ignore pointer input.
3. WHEN a Repository_Layer call returns zero items, THE Async_Surface SHALL render an Empty_State containing a heading, one explanatory sentence, and one action control that navigates to the flow that creates the first item.
4. IF a Repository_Layer call completes with an error, THEN THE Async_Surface SHALL render an Error_State containing a plain language message and a retry control that re-invokes the same call.
5. WHEN the user activates the retry control in an Error_State, THE Async_Surface SHALL return to the Loading_Skeleton state before rendering the new result.
6. WHILE the user holds a pointer on a tappable card, tile, list row, or button, THE pressed widget SHALL render at a scale of 0.98 relative to its resting size.
7. WHILE a form submission is in flight, THE submitting button SHALL render a busy indicator, SHALL keep its resting width, and SHALL reject further activation.
8. WHEN a pull to refresh gesture completes on a scrollable Async_Surface, THE Async_Surface SHALL re-invoke its Repository_Layer call and SHALL render the returned result.

### Requirement 4: Accessibility

**User Story:** As a user who relies on a screen reader and larger text, I want every control labeled and every layout tolerant of scaling, so that I can operate the application without sighted assistance.

#### Acceptance Criteria

1. THE FrostBank_App SHALL attach a semantic label to every icon only control, every card, every chip, and every list row.
2. THE FrostBank_App SHALL render every tappable target at a minimum of 48 logical pixels in width and 48 logical pixels in height.
3. WHEN the operating system text scale factor is set to 1.3, THE FrostBank_App SHALL render every UI_String without clipping and without overflow errors.
4. WHEN a monetary balance value changes on screen, THE displaying widget SHALL emit a screen reader announcement that states the account name and the new value.
5. THE FrostBank_App SHALL order focus traversal on every screen from the top leading element to the bottom trailing element in visual reading order.
6. WHEN a monetary figure is rendered, THE displaying widget SHALL expose a semantic label that reads the amount and the currency code in words.
7. WHEN a screen opens, THE screen SHALL announce its title to the screen reader.
8. THE FrostBank_App SHALL render a visible focus indicator, resolved from the Design_System accent token, on the element that holds keyboard focus.

### Requirement 5: Security Surface

**User Story:** As a user, I want the application locked, my balances hideable, and my card numbers masked, so that the application behaves like a real banking application even though the data is mock.

#### Acceptance Criteria

1. WHEN Auth_Service holds a valid session at launch, THE App_Lock SHALL require PIN entry or biometric confirmation before Dashboard_Screen content becomes visible.
2. IF the user enters an incorrect PIN five consecutive times, THEN THE App_Lock SHALL clear the session, SHALL navigate to Login_Screen, and SHALL display the reason for the lockout.
3. WHERE the device reports an enrolled biometric, THE App_Lock SHALL offer biometric confirmation as the primary unlock method and PIN entry as the fallback method.
4. WHEN FrostBank_App returns to the foreground after 120 seconds or more in the background, THE Session_Guard SHALL present App_Lock before revealing any authenticated screen.
5. WHEN FrostBank_App enters the background, THE FrostBank_App SHALL obscure authenticated screen content in the operating system task switcher preview.
6. WHEN the user activates the balance visibility control, THE Balance_Privacy_Controller SHALL replace every monetary figure in FrostBank_App with a fixed mask glyph sequence and SHALL retain the masked preference in Persistence_Store.
7. THE Card_Detail_Screen SHALL render card numbers with only the final four digits visible until the user activates the reveal control.
8. WHEN the user activates the reveal control on a card number, THE Card_Detail_Screen SHALL show the full number for 10 seconds and SHALL then return to the masked rendering.
9. THE FrostBank_App source SHALL contain no API keys, no access tokens, and no credential values.
10. WHEN the user confirms logout in Profile_Screen, THE Auth_Service SHALL clear the session and the PIN from Persistence_Store and THE Router SHALL navigate to Login_Screen.

### Requirement 6: Mock Data Layer

**User Story:** As a developer, I want all data behind repository interfaces with believable seed content, so that a real API can replace the mock implementation without touching any widget.

#### Acceptance Criteria

1. THE Repository_Layer SHALL define one abstract interface per domain for accounts, cards, transactions, savings goals, crypto holdings, split bills, time deposits, notifications, promotions, and the user profile.
2. THE FrostBank_App presentation code SHALL depend only on Repository_Layer interfaces and domain models.
3. THE Mock_Data_Source SHALL seed at least three accounts, at least two cards, at least 40 transactions spanning at least 60 days, at least two savings goals, at least three crypto holdings, at least two split bills, and at least two time deposits.
4. THE Mock_Data_Source SHALL complete every read call without any network request.
5. WHEN a Repository_Layer call is invoked, THE Mock_Data_Source SHALL return the result after a delay between 300 milliseconds and 900 milliseconds so that Loading_Skeleton rendering is observable.
6. WHEN a write call succeeds, THE Mock_Data_Source SHALL apply the mutation to its in memory state and SHALL persist the mutated state to Persistence_Store.
7. WHEN FrostBank_App launches and Persistence_Store holds a previously persisted data set, THE Mock_Data_Source SHALL load that persisted data set instead of reseeding.
8. WHERE a developer enables the error simulation flag for a repository, THE Mock_Data_Source SHALL return a domain error for calls to that repository so that Error_State rendering can be verified.
9. THE Mock_Data_Source seed definitions SHALL carry a code comment marking every monetary figure and every rate as mock data.

### Requirement 7: State Management and Navigation

**User Story:** As a developer, I want declarative routing with an authentication guard and Riverpod providers for all async state, so that navigation and data flow stay predictable.

#### Acceptance Criteria

1. THE FrostBank_App SHALL expose every Repository_Layer read through a flutter_riverpod provider and SHALL render its result through an async value state.
2. THE Router SHALL declare a named route for Splash_Screen, Login_Screen, Register_Screen, Forgot_Password_Screen, Dashboard_Screen, Account_Detail_Screen, Card_Detail_Screen, Transaction_History_Screen, Transfer_Flow, Deposit_Flow, QR_Scan_Screen, Savings_Screen, Crypto_Screen, Split_Bills_Screen, Time_Deposit_Screen, Notifications_Screen, and Profile_Screen.
3. IF an unauthenticated user requests an authenticated route, THEN THE Session_Guard SHALL redirect that request to Login_Screen.
4. IF an authenticated user requests Login_Screen, Register_Screen, or Forgot_Password_Screen, THEN THE Session_Guard SHALL redirect that request to Dashboard_Screen.
5. THE Router SHALL host Dashboard_Screen, Transaction_History_Screen, Finance_Hub screens, and Profile_Screen inside a ShellRoute that renders Shell_Nav.
6. THE Shell_Nav SHALL render as a floating pill with four peripheral destinations and the brand mark as the center destination.
7. WHEN the user selects a Shell_Nav destination, THE Router SHALL navigate to that destination and THE Shell_Nav SHALL mark that destination as active using the Design_System accent token.
8. WHEN the user selects the already active Shell_Nav destination, THE Router SHALL return that destination branch to its first route.
9. WHEN the user navigates within a Shell_Nav branch and then switches branches and returns, THE Router SHALL restore the previous scroll position and route of the returning branch.
10. IF a requested route does not exist, THEN THE Router SHALL render an error screen with a control that returns to Dashboard_Screen.

### Requirement 8: Splash and Launch

**User Story:** As a user, I want a short branded launch screen, so that I know the application is starting and where my session stands.

#### Acceptance Criteria

1. WHEN FrostBank_App launches, THE Splash_Screen SHALL render the FrostBank brand mark over the Primary gradient with a grain overlay.
2. WHILE Splash_Screen is resolving the session, THE Splash_Screen SHALL render a bounded load indicator.
3. WHEN session resolution completes and no valid session exists, THE Router SHALL navigate to Login_Screen.
4. WHEN session resolution completes and a valid session exists, THE Router SHALL present App_Lock and then navigate to Dashboard_Screen.
5. THE Splash_Screen SHALL remain visible for at most 2000 milliseconds before navigating.
6. IF session resolution fails, THEN THE Splash_Screen SHALL navigate to Login_Screen and SHALL display a message stating that the session could not be restored.

### Requirement 9: Login

**User Story:** As a returning customer, I want to sign in with my email and password, so that I can reach my accounts.

#### Acceptance Criteria

1. THE Login_Screen SHALL render the Primary gradient with a grain overlay, the brand mark in the top area, an uppercase display headline, one subtext paragraph of at most 20 words, and a bottom anchored action stack.
2. THE Login_Screen SHALL render the primary action as a full width white pill button and the secondary action as a plain text link below that button.
3. THE Login_Screen SHALL render a label above each input field and helper or error text below each input field.
4. WHEN the user submits the form with a well formed email and a password of at least 8 characters, THE Auth_Service SHALL validate the credentials against Mock_Data_Source.
5. WHEN Auth_Service validates the credentials successfully, THE Auth_Service SHALL create a session, THE Persistence_Store SHALL retain that session, and THE Router SHALL navigate to Dashboard_Screen.
6. IF the submitted email is not well formed, THEN THE Login_Screen SHALL render an inline message below the email field stating the expected format.
7. IF the submitted password is shorter than 8 characters, THEN THE Login_Screen SHALL render an inline message below the password field stating the minimum length.
8. IF Auth_Service rejects the credentials, THEN THE Login_Screen SHALL render an inline message above the primary action stating that the email or password is incorrect, and SHALL retain the entered email.
9. THE Login_Screen SHALL render a control that toggles password character visibility, with a semantic label that states the current visibility.
10. WHERE the device reports an enrolled biometric and Persistence_Store holds a previous session, THE Login_Screen SHALL render a biometric sign in control.

### Requirement 10: Register

**User Story:** As a new customer, I want to create an account with my details, so that I can start using the application.

#### Acceptance Criteria

1. THE Register_Screen SHALL collect full name, email, mobile number, password, and password confirmation.
2. WHEN the user submits the form and every field satisfies its validation rule, THE Auth_Service SHALL create a profile in Mock_Data_Source, SHALL create a session, and THE Router SHALL navigate to the PIN setup step.
3. IF the password confirmation does not match the password, THEN THE Register_Screen SHALL render an inline message below the confirmation field stating that the values must match.
4. IF the submitted email already exists in Mock_Data_Source, THEN THE Register_Screen SHALL render an inline message below the email field stating that the email is already registered.
5. WHILE the password field holds text, THE Register_Screen SHALL render a strength indicator with the states weak, fair, and strong resolved from Design_System semantic tokens.
6. WHEN the user completes the PIN setup step with two matching six digit entries, THE App_Lock SHALL store the PIN in Persistence_Store and THE Router SHALL navigate to Dashboard_Screen.
7. THE Register_Screen SHALL render a control that navigates to Login_Screen for users who already hold an account.

### Requirement 11: Forgot Password

**User Story:** As a customer who forgot my password, I want a reset path, so that I can regain access.

#### Acceptance Criteria

1. THE Forgot_Password_Screen SHALL collect the registered email address.
2. WHEN the user submits a well formed email that exists in Mock_Data_Source, THE Forgot_Password_Screen SHALL navigate to a code entry step and SHALL state that a six digit code was sent to that email.
3. WHEN the user submits a well formed email that does not exist in Mock_Data_Source, THE Forgot_Password_Screen SHALL navigate to the code entry step and SHALL display the same message, so that registered addresses are not disclosed.
4. WHEN the user enters the mock verification code that Mock_Data_Source accepts, THE Forgot_Password_Screen SHALL navigate to the new password step.
5. IF the entered verification code is rejected, THEN THE Forgot_Password_Screen SHALL render an inline message stating that the code is incorrect and SHALL keep the user on the code entry step.
6. WHEN the user submits a new password of at least 8 characters with a matching confirmation, THE Auth_Service SHALL update the stored credential and THE Router SHALL navigate to Login_Screen with a confirmation message.
7. THE Forgot_Password_Screen code entry step SHALL render a resend control that becomes available 30 seconds after the previous send.

### Requirement 12: Dashboard

**User Story:** As a customer, I want one screen that shows my money, my quick actions, my cards, and my recent activity, so that I can act without hunting through menus.

#### Acceptance Criteria

1. THE Dashboard_Screen SHALL render the Primary gradient behind the top region and SHALL render the lower content inside a white rounded sheet that overlaps that gradient.
2. THE Dashboard_Screen SHALL render a rounded search field with two trailing icon controls in the top region.
3. THE Dashboard_Screen SHALL render a horizontal account chip row where each chip shows the account or currency code and its balance, and THE active chip SHALL carry an underline indicator resolved from the Design_System accent token.
4. WHEN the user selects an account chip, THE Dashboard_Screen SHALL update the large balance figure, the Cards_Carousel selection, and the recent transaction list to that account.
5. THE Dashboard_Screen SHALL render the selected account total balance as a single large figure in GeistMono and SHALL render the available balance as a smaller secondary line below that figure.
6. THE Dashboard_Screen SHALL render a Cards_Carousel of horizontal card thumbnails ending with an add card tile.
7. THE Dashboard_Screen SHALL render a quick action row of exactly four squircle tiles labeled Deposit, Send, Scan, and History, each with a dark icon chip and a small uppercase label.
8. WHEN the user activates a quick action tile, THE Router SHALL navigate to Deposit_Flow, Transfer_Flow, QR_Scan_Screen, or Transaction_History_Screen respectively.
9. THE Dashboard_Screen SHALL render a Finance_Hub section with exactly four entries labeled Savings, Crypto, Split Bills, and Time Deposit.
10. WHEN the user activates a Finance_Hub entry, THE Router SHALL navigate to the matching Finance Hub screen.
11. THE Dashboard_Screen SHALL render a transactions section with the heading Transactions and a View all control that navigates to Transaction_History_Screen.
12. THE Dashboard_Screen transactions section SHALL group rows under day headers and SHALL render each row as a circular merchant avatar, the merchant name, a category subtitle, a right aligned amount, and a smaller secondary line below that amount.
13. THE Dashboard_Screen transactions section SHALL render at most the eight most recent transactions.
14. THE Dashboard_Screen SHALL render a Promo_Carousel of image cards, each with a title of at most 6 words and one action control.
15. WHEN the user activates the notifications icon control, THE Router SHALL navigate to Notifications_Screen.
16. WHILE Notifications_Screen holds at least one unread notification, THE Dashboard_Screen notifications control SHALL render an unread count badge.
17. WHEN a Repository_Layer balance value changes, THE Dashboard_Screen SHALL animate the balance figure using opacity and translation within the medium duration band.

### Requirement 13: Cards

**User Story:** As a cardholder, I want to browse my cards and read their details, so that I can copy a card number or check a card balance.

#### Acceptance Criteria

1. WHEN the user selects a card thumbnail in Cards_Carousel, THE Router SHALL navigate to Card_Detail_Screen for that card.
2. THE Card_Detail_Screen SHALL render the selected card using the Card gradient inside a peeking card stack with a page dot indicator.
3. WHEN the user swipes horizontally on the card stack, THE Card_Detail_Screen SHALL bring the adjacent card to the front and SHALL move the page dot indicator to the matching position.
4. THE Card_Detail_Screen SHALL render the card balance below the card stack as a large GeistMono figure.
5. THE Card_Detail_Screen SHALL render a Card info list of label and value rows covering card holder, card number, expiry, network, and status.
6. THE Card_Detail_Screen SHALL render a copy control on the card number row.
7. WHEN the user activates the copy control, THE Card_Detail_Screen SHALL place the unmasked card number on the system clipboard and SHALL display a confirmation message for 2 seconds.
8. THE Card_Detail_Screen SHALL render controls to freeze the card and to set a spending limit, and each control SHALL persist its result through Repository_Layer.
9. WHEN the user activates the add card tile in Cards_Carousel, THE Router SHALL navigate to a card creation form that writes the new card through Repository_Layer.
10. THE Card_Detail_Screen SHALL render the card number and expiry values in GeistMono.

### Requirement 14: Accounts

**User Story:** As a customer, I want a detail screen for each of my Savings Account, Wallet, and Crypto Wallet, so that I can see the balance and activity for each one.

#### Acceptance Criteria

1. THE Account_Detail_Screen SHALL render the account name, the account type, the masked account identifier, the total balance, and the available balance.
2. THE Account_Detail_Screen SHALL render an inflow total and an outflow total for the current calendar month.
3. THE Account_Detail_Screen SHALL render the transactions belonging to that account, grouped under day headers.
4. THE Account_Detail_Screen SHALL render account specific actions, where the Savings Account offers Deposit and Transfer, the Wallet offers Deposit, Send, and Scan, and the Crypto Wallet offers Buy, Sell, and Send.
5. WHERE the account is the Crypto Wallet, THE Account_Detail_Screen SHALL render the holding value in the local currency and the holding quantity in the crypto unit.
6. WHEN the user activates an account action, THE Router SHALL navigate to the matching flow with the account preselected.
7. THE Account_Detail_Screen SHALL render every monetary figure in GeistMono.

### Requirement 15: Transaction History

**User Story:** As a customer, I want to search and filter my full transaction history, so that I can find a specific payment.

#### Acceptance Criteria

1. THE Transaction_History_Screen SHALL render all transactions in reverse chronological order, grouped under day headers.
2. THE Transaction_History_Screen SHALL render each row as a circular merchant avatar, the merchant name, a category subtitle, a right aligned signed amount, and a smaller secondary line below that amount.
3. THE Transaction_History_Screen SHALL render a filter control that opens a filter sheet offering transaction type, date range, and account.
4. THE Transaction_Filter SHALL offer the transaction type values Deposit, Transfer, QR Payment, and Card Purchase.
5. WHEN the user applies a Transaction_Filter, THE Transaction_History_Screen SHALL render only the transactions that satisfy every selected criterion and SHALL render the active criteria as removable chips above the list.
6. WHEN the user removes an active filter chip, THE Transaction_History_Screen SHALL clear that single criterion and SHALL retain the remaining criteria.
7. WHEN the user enters text in the search field, THE Transaction_History_Screen SHALL render only the transactions whose merchant name or reference contains that text, matched without case sensitivity.
8. IF an applied Transaction_Filter matches zero transactions, THEN THE Transaction_History_Screen SHALL render an Empty_State whose action clears the filter.
9. WHEN the user selects a transaction row, THE Router SHALL navigate to a transaction detail screen showing the merchant, the amount, the account, the date and time, the reference, the status, and the category.
10. WHEN the user scrolls to the end of the loaded list, THE Transaction_History_Screen SHALL request the next 20 transactions from Repository_Layer and SHALL append the returned rows.
11. THE Transaction_History_Screen SHALL render a control that exports the filtered result to a local file and SHALL display the export result.

### Requirement 16: Transfer and Send Money

**User Story:** As a customer, I want to send money in clear steps with a review before confirming, so that I do not send the wrong amount to the wrong person.

#### Acceptance Criteria

1. THE Transfer_Flow SHALL present exactly four steps in the order recipient, amount, review, and result.
2. THE Transfer_Flow recipient step SHALL render a saved recipient list and a field that accepts an account number or a mobile number.
3. WHEN the user enters a recipient identifier that Mock_Data_Source resolves, THE Transfer_Flow SHALL render the resolved recipient name before enabling the next step.
4. IF the entered recipient identifier is not resolved by Mock_Data_Source, THEN THE Transfer_Flow SHALL render an inline message stating that the recipient was not found and SHALL keep the next step disabled.
5. THE Transfer_Flow amount step SHALL render a source account selector, a numeric amount field in GeistMono, an optional note field of at most 60 characters, and the available balance of the selected source account.
6. IF the entered amount exceeds the available balance of the selected source account, THEN THE Transfer_Flow SHALL render an inline message stating that the balance is insufficient and SHALL keep the next step disabled.
7. IF the entered amount is zero or negative, THEN THE Transfer_Flow SHALL keep the next step disabled.
8. THE Transfer_Flow review step SHALL render the recipient, the source account, the amount, the fee, the total to be debited, and the note.
9. WHEN the user confirms the review step, THE App_Lock SHALL require PIN entry or biometric confirmation before Repository_Layer performs the transfer.
10. WHEN Repository_Layer completes the transfer, THE Transfer_Flow result step SHALL render a success message, the reference identifier, and controls to share the receipt and to return to Dashboard_Screen.
11. IF Repository_Layer returns an error for the transfer, THEN THE Transfer_Flow result step SHALL render the failure reason, a retry control, and a statement that no funds left the source account.
12. WHEN a transfer completes, THE Repository_Layer SHALL reduce the source account balance, SHALL create a transaction record of type Transfer, and SHALL persist both changes.
13. WHEN the user leaves Transfer_Flow before confirming, THE Transfer_Flow SHALL discard the entered values.

### Requirement 17: Deposit and QR Payment

**User Story:** As a customer, I want to add funds and to pay by scanning a code, so that the quick actions on the dashboard do real work.

#### Acceptance Criteria

1. THE Deposit_Flow SHALL collect a destination account, a mock funding source, and an amount.
2. WHEN the user confirms a deposit, THE Repository_Layer SHALL increase the destination account balance, SHALL create a transaction record of type Deposit, and SHALL persist both changes.
3. IF the entered deposit amount is zero or negative, THEN THE Deposit_Flow SHALL keep the confirm control disabled.
4. THE QR_Scan_Screen SHALL render a camera viewport frame, a torch control, and a control to enter a payment code manually.
5. IF camera permission is denied, THEN THE QR_Scan_Screen SHALL render a message explaining the denial and a control that opens the operating system settings.
6. WHEN a payment code is captured or entered, THE QR_Scan_Screen SHALL render the resolved merchant name and amount for confirmation before any debit occurs.
7. WHEN the user confirms a QR payment, THE App_Lock SHALL require PIN entry or biometric confirmation, THE Repository_Layer SHALL reduce the source account balance, and THE Repository_Layer SHALL create a transaction record of type QR Payment.
8. IF a captured payment code cannot be resolved, THEN THE QR_Scan_Screen SHALL render a message stating that the code is not recognized and SHALL resume scanning.

### Requirement 18: Finance Hub Savings

**User Story:** As a saver, I want to track goals and move money into them, so that I can see progress toward each goal.

#### Acceptance Criteria

1. THE Savings_Screen SHALL render every savings goal with its name, its target amount, its saved amount, and its progress as a percentage.
2. THE Savings_Screen SHALL render the total saved across all goals as a single large GeistMono figure.
3. WHEN the user creates a savings goal with a name, a target amount, and a target date, THE Repository_Layer SHALL persist that goal and THE Savings_Screen SHALL render it.
4. WHEN the user adds funds to a goal from a source account, THE Repository_Layer SHALL reduce the source account balance, SHALL increase the goal saved amount, and SHALL create a transaction record.
5. IF the amount added to a goal exceeds the available balance of the source account, THEN THE Savings_Screen SHALL render an inline message stating that the balance is insufficient.
6. WHEN a goal saved amount reaches its target amount, THE Savings_Screen SHALL render that goal with the Success semantic token and SHALL label the goal as reached.
7. WHEN the user withdraws from a goal to an account, THE Repository_Layer SHALL reduce the goal saved amount, SHALL increase the account balance, and SHALL create a transaction record.
8. IF Savings_Screen holds zero goals, THEN THE Savings_Screen SHALL render an Empty_State whose action opens the goal creation form.

### Requirement 19: Finance Hub Crypto

**User Story:** As a crypto holder, I want to see my holdings and simulate buys and sells, so that the crypto wallet reflects believable activity.

#### Acceptance Criteria

1. THE Crypto_Screen SHALL render the total portfolio value in the local currency and the change over the last 24 hours as a signed percentage.
2. THE Crypto_Screen SHALL render every holding with its asset name, its asset symbol, its quantity, its local currency value, and its 24 hour change.
3. THE Crypto_Screen SHALL render a signed 24 hour change using the Success semantic token for a positive value and the Error semantic token for a negative value.
4. THE Crypto_Screen SHALL render a price history chart for the selected asset with selectable ranges of 24 hours, 7 days, 30 days, and 1 year.
5. WHEN the user confirms a buy with an amount in local currency, THE Repository_Layer SHALL reduce the source account balance, SHALL increase the asset quantity at the mock rate, and SHALL create a transaction record.
6. WHEN the user confirms a sell with a quantity, THE Repository_Layer SHALL reduce the asset quantity, SHALL increase the destination account balance at the mock rate, and SHALL create a transaction record.
7. IF the sell quantity exceeds the held quantity, THEN THE Crypto_Screen SHALL render an inline message stating the maximum quantity available.
8. THE Crypto_Screen SHALL render a statement identifying every rate as mock data.
9. THE Crypto_Screen SHALL render every quantity and every rate in GeistMono.

### Requirement 20: Finance Hub Split Bills

**User Story:** As someone who shares costs, I want to split a bill among people and track who has paid, so that settling up is clear.

#### Acceptance Criteria

1. THE Split_Bills_Screen SHALL render every split bill with its title, its total amount, the participant count, and the settled amount.
2. WHEN the user creates a split bill with a title, a total amount, and at least two participants, THE Repository_Layer SHALL persist that bill and THE Split_Bills_Screen SHALL render it.
3. WHEN the user selects the equal split method, THE Split_Bills_Screen SHALL assign each participant the total amount divided by the participant count and SHALL assign any rounding remainder to the bill creator.
4. WHEN the user selects the custom split method, THE Split_Bills_Screen SHALL accept a per participant amount and SHALL render the difference between the assigned sum and the bill total.
5. IF the sum of custom participant amounts differs from the bill total, THEN THE Split_Bills_Screen SHALL keep the save control disabled and SHALL render the outstanding difference.
6. WHEN a participant share is marked as paid, THE Repository_Layer SHALL increase the bill settled amount and THE Split_Bills_Screen SHALL render that participant using the Success semantic token.
7. WHEN every participant share of a bill is marked as paid, THE Split_Bills_Screen SHALL label that bill as settled and SHALL move it to a settled group.
8. WHEN the user requests a reminder for an unpaid participant, THE Split_Bills_Screen SHALL create a notification record through Repository_Layer.
9. IF Split_Bills_Screen holds zero bills, THEN THE Split_Bills_Screen SHALL render an Empty_State whose action opens the bill creation form.

### Requirement 21: Finance Hub Time Deposit

**User Story:** As a customer looking for yield, I want to open and track time deposits, so that I can see maturity dates and projected interest.

#### Acceptance Criteria

1. THE Time_Deposit_Screen SHALL render every time deposit with its principal, its annual rate, its term in months, its start date, its maturity date, and its projected interest at maturity.
2. THE Time_Deposit_Screen SHALL render the total principal placed across all deposits as a single large GeistMono figure.
3. THE Time_Deposit_Screen SHALL offer term options of 3 months, 6 months, 12 months, and 24 months, each with its own annual rate from Mock_Data_Source.
4. WHEN the user enters a principal and selects a term, THE Time_Deposit_Screen SHALL render the projected interest and the maturity date before the user confirms.
5. WHEN the user confirms a time deposit, THE Repository_Layer SHALL reduce the source account balance by the principal, SHALL create the deposit record, and SHALL create a transaction record.
6. IF the entered principal is below the minimum principal defined by Mock_Data_Source, THEN THE Time_Deposit_Screen SHALL render an inline message stating that minimum and SHALL keep the confirm control disabled.
7. WHILE a time deposit has not reached its maturity date, THE Time_Deposit_Screen SHALL render the days remaining until maturity.
8. WHEN the user withdraws a time deposit before its maturity date, THE Time_Deposit_Screen SHALL render the early withdrawal penalty and the net amount for confirmation before Repository_Layer performs the withdrawal.
9. WHEN a time deposit reaches its maturity date, THE Repository_Layer SHALL increase the linked account balance by the principal plus the interest and SHALL create a notification record.
10. THE Time_Deposit_Screen SHALL render a statement identifying every rate as mock data.

### Requirement 22: Notifications

**User Story:** As a customer, I want a list of notifications with clear read state, so that I can catch up on activity.

#### Acceptance Criteria

1. THE Notifications_Screen SHALL render every notification with its title, its body of at most 20 words, its relative timestamp, and its category.
2. THE Notifications_Screen SHALL render unread notifications with a stronger surface tint than read notifications.
3. WHEN the user opens a notification, THE Repository_Layer SHALL mark that notification as read and THE Notifications_Screen SHALL update the unread count.
4. WHEN the user activates the mark all as read control, THE Repository_Layer SHALL mark every notification as read.
5. WHERE a notification carries a linked target, THE Notifications_Screen SHALL render a control that navigates to that target.
6. IF Notifications_Screen holds zero notifications, THEN THE Notifications_Screen SHALL render an Empty_State.

### Requirement 23: Profile, Settings, and Security

**User Story:** As a customer, I want one place for my details, my preferences, my security controls, and logout, so that I can manage the application.

#### Acceptance Criteria

1. THE Profile_Screen SHALL render the user avatar, the full name, the masked email, and the masked mobile number.
2. WHEN the user edits a profile field and saves, THE Repository_Layer SHALL persist the change and THE Profile_Screen SHALL render the updated value.
3. THE Profile_Screen SHALL render a settings section containing a theme option with the values System, Light, and Dark, a language option, and a currency display option.
4. THE Profile_Screen SHALL render a security section containing controls to change the PIN, to toggle biometric unlock, to toggle balance masking, and to set the session timeout.
5. WHEN the user changes the PIN, THE App_Lock SHALL require the current PIN before accepting two matching new six digit entries.
6. IF the entered current PIN is incorrect, THEN THE Profile_Screen SHALL render an inline message stating that the PIN is incorrect and SHALL keep the current PIN in place.
7. WHERE the device reports no enrolled biometric, THE Profile_Screen SHALL render the biometric unlock control in a disabled state with a message stating that no biometric is enrolled.
8. WHEN the user activates logout, THE Profile_Screen SHALL request confirmation before Auth_Service clears the session.
9. THE Profile_Screen SHALL render a control that opens an About section stating that all figures in the application are mock data.

### Requirement 24: Content Authenticity

**User Story:** As a reviewer, I want the seeded content to read like a real customer's account, so that the application demonstrates believable behavior.

#### Acceptance Criteria

1. THE Mock_Data_Source SHALL seed the customer name and every recipient name as a locale appropriate full name.
2. THE Mock_Data_Source SHALL seed every merchant as a plausible named business with a category, and no seeded merchant name SHALL be a generic placeholder.
3. THE Mock_Data_Source SHALL seed transaction amounts with non rounded values and varied intervals across the seeded date range.
4. THE Mock_Data_Source SHALL seed every masked identifier, including account numbers and card numbers, with digits that pass the format check of its network or scheme.
5. THE Mock_Data_Source SHALL seed at least one failed transaction and at least one pending transaction so that non success statuses are visible.
6. THE Promo_Carousel content SHALL reference a named product or offer with a concrete benefit.
7. THE FrostBank_App SHALL render every merchant avatar as either a seeded image asset or a monogram derived from the merchant name.

### Requirement 25: Copy Discipline

**User Story:** As a reader of the interface, I want plain functional copy without decorative filler, so that every string on screen carries meaning.

#### Acceptance Criteria

1. THE FrostBank_App SHALL contain no em dash character and no en dash character in any UI_String.
2. THE FrostBank_App SHALL contain no scroll cue text and no scroll cue indicator.
3. THE FrostBank_App SHALL contain no version label and no build label in any UI_String.
4. WHERE a colored status indicator is rendered, THE indicator SHALL be bound to a real semantic state value from Repository_Layer.
5. THE FrostBank_App SHALL render every button label on a single line at a text scale factor of 1.0 and at a text scale factor of 1.3.
6. THE FrostBank_App SHALL limit every primary button label to at most 3 words.
7. THE FrostBank_App SHALL limit every screen subtext paragraph to at most 25 words.
8. THE FrostBank_App SHALL use one label per action intent across every screen, so that a single intent never appears under two different labels.
