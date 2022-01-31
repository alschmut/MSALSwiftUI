# MSALSwiftUI

This project intends to give an example of how the MSAL iOS library can be used in a SwiftUI App. 
It uses the same MSAL APIs but separated from the View. 
This projects reuses the sample code provided by Microsoft within their MSAL iOS Sample Project:

https://github.com/Azure-Samples/ms-identity-mobile-apple-swift-objc

**Important**: I do not guarantee that this project works 100% the same way as the MS Sample does! But I hope it gives some useful input while trying to rewrite the UIKIt sample in SwiftUI :)



## Use your own Azure App

To use this project with your own registered Azure App you need to change the following:
* Project *Bundle Identifier* (`<app_name>` -> `<your_target>` -> General -> Bundle Identifier)
* Replace the credentials in `MSAuthCredentials.swift
  ```swift
  struct MSAuthCredentials {
    static let applicationId = "66855f8a-60cd-445e-a9bb-8cd8eadbd3fa" // or clientID
    static let directoryId = "common" // or tenantID
  }
  ```


## Overview
The [`MSAuthAdapter`](Shared/MSAuthAdapter.swift) encapsulates all the MSAL APIs, which mainly stayed the same as in the above mentioned UIKit sample.

```swift
class MSAuthState: ObservableObject {
    @Published var currentAccount: MSALAccount?
    @Published var logMessage = ""
}

struct AuthView: View {
    @EnvironmentObject var msAuthState: MSAuthState

    private let msAuthAdapter: MSAuthAdapter = resolve()
    
    var body: some View {
        VStack(spacing: 40) {
            Text(msAuthState.currentAccount?.username ?? "Signed out")
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundColor(.gray)

            Button("Call Microsoft Graph API") {
                msAuthAdapter.callGraphAPI()
            }

            Button("Sign Out") {
                msAuthAdapter.signOut()
            }
            .disabled(msAuthState.currentAccount == nil)

            Button("Get device info") {
                msAuthAdapter.getDeviceMode()
            }
            
            Text(msAuthState.logMessage)
                .font(.caption)

            Spacer()
        }
        .padding()
    }
}

```


## Dependencies
* [Resolver](https://github.com/hmlongco/Resolver) for simple dependency injection


## Roadmap

I do not intend to update this project or keep it up to date. 
Microsoft itself is likely to introduce their own Sample Project for SwiftUI soon (state August 2021).
See issue regarding SwiftUI Sample for a similar project https://github.com/Azure-Samples/active-directory-b2c-ios-swift-native-msal/issues/47


## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are greatly appreciated.

1. Fork the Project
2. Create your Feature Branch
3. Commit your Changes
4. Push to the Branch
5. Open a Pull Request


## License

Distributed under the MIT License. See `LICENSE` for more information.


## Contact

Alexander Schmutz - alexander@t-schmutz.de


## Acknowledgements
* [Resolver](https://github.com/hmlongco/Resolver)
* [MSAL iOS Sample Code](https://github.com/AzureAD/microsoft-authentication-library-for-objc)
