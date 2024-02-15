import darkModeCode from "dark-mode-code";

import { Html, Head, Main, NextScript } from "next/document";

export default function Document() {
  return (
    <Html>
      <Head />
      <body>
        <script dangerouslySetInnerHTML={{ __html: darkModeCode }}></script>
        <Main />
        <NextScript />
      </body>
    </Html>
  );
}
