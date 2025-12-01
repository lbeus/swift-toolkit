# EPUBNavigatorDelegate

Readium allows rendering EPUB spine elements in a custom way (e.g. PDF is rendered using PDFKit instead of being loaded in WKWebView).
Client can add custom overlay on top of WKWebView using 
```swift 
func navigator(_ navigator: EPUBNavigatorViewController, renderNativeOverlay spreadView: UIView, using params: Any)
```
 delegate method.

In order for this method to be invoked for given ```EPUBSpreadView```, loaded XHTML resource must have ```link``` tag element inside ```head``` block.

```html
<link href="pages/sample-page.pdf" rel="preload" type="application/pdf" class="wrapped-resource" kind="pdf"/>
```

Link tag must have class set to ```wrapped-resource```.  ```href``` attribute is used to identify resource registered in EPUB which client can render in custom way, and ```kind``` is arbtrary type used by client to define how given resource should be rendered. 
