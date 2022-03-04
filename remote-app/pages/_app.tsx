import "../styles/globals.css";
import type { AppProps } from "next/app";
import { useEffect } from "react";
import axios from "../lib/axios";

function MyApp({ Component, pageProps }: AppProps) {
  useEffect(() => {
    axios.get("http://localhost:3000/session");
  }, []);

  return <Component {...pageProps} />;
}

export default MyApp;
