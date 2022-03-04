import type { NextPage } from "next";
import Head from "next/head";
import styles from "../styles/Home.module.css";
import axios from "../lib/axios";
import * as React from "react";

const Home: NextPage = () => {
  const onSubmit = async (e: React.SyntheticEvent) => {
    e.preventDefault();
    console.log("submit");

    const target = e.target as typeof e.target & {
      email: { value: string };
      password: { value: string };
    };

    const { data } = await axios.post("http://localhost:3000/users/sign_in", {
      user: {
        email: target.email.value,
        password: target.password.value,
        remember_me: 0,
      },
    });

    console.log(data);
  };

  const testEndpoint = async () => {
    try {
      const { data } = await axios.post("http://localhost:3000/home");
      console.log(data);
    } catch (e) {
      console.error(e);
    }
  };

  return (
    <div className={styles.container}>
      <Head>
        <title>Create Next App</title>
        <meta name="description" content="Generated by create next app" />
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <main className={styles.main}>
        <form onSubmit={onSubmit}>
          <div>
            <input name="email" type="text" placeholder="Email" />
          </div>
          <div>
            <input name="password" type="password" placeholder="Password" />
          </div>
          <div>
            <button type="submit">Sign in</button>
          </div>
        </form>
        <button onClick={testEndpoint}>Test Endpoint</button>
      </main>
    </div>
  );
};

export default Home;
