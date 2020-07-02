import Document, { Main, NextScript, Html, Head } from 'next/document'

const darkModeCode = require('dark-mode-code')

export default () => {

  return (
    <Html>
      <body>
        <script dangerouslySetInnerHTML={{ __html: darkModeCode }}></script>
        <Main />
        <NextScript />
      </body>
    </Html>
  )
}

