# EPUBNavigatorDelegate

Readium allows rendering EPUB spine elements in a custom way (e.g. PDF is rendered using PDFKit instead of being loaded in WKWebView).
Client can provide custom view for given spread using 
```swift 
    func navigator(_ navigator: EPUBNavigatorViewController, viewControllersForReadingOrderLinks links: [Link]) -> (left: UIViewController?, center: UIViewController?, right: UIViewController?)
```
 delegate method.
 
 Returned tuple contains left and right pages if spread has 2 pages. Center property is used in case spread has 1 page.
 In case any of spread pages doesn't require custom view ```nil``` is returned for such page, and readium will fallback to webview rendering.

```links``` contains array of EPUB spine element links (if spread has 2 pages it will have 2 links, otherwise 1 link).
EPUB document could hold JSON resource which contains mapping of spine element links to metadata model needed to perform custom rendering (e.g. asset hrefs, custom view type info ...)
