import Document, { Main, NextScript, Html, Head } from 'next/document'
import darkModeCode from 'dark-mode-code'

export default class MyDocument extends Document {
  static async getInitialProps(ctx) {
    const initalProps = await Document.getInitialProps(ctx)

    return {...initalProps}
  }
  render() {
    return (
      <Html>
        <Head />
        <body>
          <script dangerouslySetInnerHTML={{ __html: darkModeCode }}></script>
          <Main />
          <NextScript />
        </body>
      </Html>
    )
  }
}
