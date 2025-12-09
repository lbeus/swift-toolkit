# EPUBNavigatorDelegate

Readium allows rendering EPUB spine elements in a custom way (e.g. PDF is rendered using PDFKit instead of being loaded in WKWebView).
Client can provide custom view for given page using 
```swift 
func navigator(_ navigator: EPUBNavigatorViewController, viewForReadingOrderLinks links: [Link]) -> UIViewController?
```
 delegate method.

In order for this method to be invoked for given resource/spine element must have ```properties``` attribute configured with appropriate metadata needed to able to render custom spread.

```html
 <item id="item-page-1" href="001-chapter.xhtml" media-type="application/xhtml+xml properties="document:pages/pg-1605839.pdf custom-type:pdf"/>
```

```properties``` attribute contains document reference and custom type which are used by the client to render given resource.
