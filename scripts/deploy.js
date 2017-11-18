const allSet = process.env.ICLOG_ALL_SET;

if (!allSet) {
  throw new Error(`

  Please set environment variables!

  `);
}

