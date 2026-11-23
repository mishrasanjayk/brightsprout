# Sprout AI server

`sprout.js` is a tiny Cloudflare Worker that lets Sprout, the in-app study buddy, think on the live BrightSprout site.
The web app is a static page and must never hold an AI key, so this server holds it, adds Sprout's kid-safety rules
on the server side, checks every request, and rate limits each device. It stores nothing.

## Set up (about 10 minutes, free Cloudflare account)

1. **Claude API key.** At console.anthropic.com, sign up, add a small credit (for example $5) under Billing,
   set a monthly spend limit (for example $10) under Limits, then create an API key under API Keys.
   Keep the key private. Do not paste it into chats, email or the app.
2. **Worker.** At dash.cloudflare.com, sign up (free), open **Workers & Pages**, choose **Create**, start from
   **Hello World**, name it `sprout`, and **Deploy**. Then choose **Edit code**, replace everything with the
   contents of `sprout.js`, and **Deploy** again.
3. **Secret.** In the worker, open **Settings → Variables and Secrets → Add**. Type: **Secret**, name:
   `ANTHROPIC_API_KEY`, value: your key. Save and deploy.
4. **Check.** Open the worker's address (like `https://sprout.yourname.workers.dev`). It should say
   "Sprout is awake 🌱". Put that address in `SPROUT_API` in `index.html`.

Free option without a card: skip step 1 and step 3, and instead add a **Workers AI** binding named `AI`
(Settings → Bindings). Sprout then uses Cloudflare's free Llama model, which is less careful than Claude.

## Settings (optional variables)

- `ALLOWED_ORIGINS`: sites allowed to call Sprout. Default `https://mishrasanjayk.github.io`.
- `MODEL`: Claude model. Default `claude-haiku-5-5`.
- `AI_MODEL`: Workers AI model when using the free option.

## Privacy and safety

- The app sends only the child's age, grade, US state and the last few chat messages. Never the name.
- Phone numbers, emails and street addresses are blanked before anything reaches the AI.
- Sprout's rules live here, so the app cannot change them.
- Limits: 6 questions a minute, 60 an hour and 200 a day per device, 3,000 a day in total (per server instance).
