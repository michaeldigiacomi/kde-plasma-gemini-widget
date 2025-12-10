# 🚀 Vibe Coding with Gemini: Building a KDE Plasma Widget 🐧

I just shipped a new update to my **Gemini Desktop Widget** for KDE Plasma, and I wanted to share a bit about the process. I didn't just write this *with* AI; I "vibe coded" it with **Gemini**.

For those not in the loop, **Vibe Coding** isn't about letting the AI do everything while you sleep. It's about a high-velocity, iterative feedback loop where you focus on the *intent* and the *architecture*, and the AI handles the syntax and the boilerplate. It's pair programming at the speed of thought.

## 🛠️ What We Built
A fully functional Plasma Widget that brings Google's Gemini models right to your desktop.
- **Dynamic Model Fetching**: Switches between `gemini-1.5-flash`, `pro`, and others instantly.
- **Markdown Support**: Nicely renders code blocks and rich text.
- **Memory**: Context-aware chat history.
- **Automation**: GitHub Actions workflow to auto-publish releases.
- **Custom Branding**: AI-generated glassmorphism icon.

## 🧩 Challenges
Building for a desktop environment like KDE Plasma comes with unique constraints compared to web dev:
1.  **QML & JavaScript Context**: Plasma widgets use QML for UI and a specific JS environment for logic. Context switching between declarative UI validation and imperative logic can be tricky.
2.  **Asynchronous by Default**: Network calls in a UI thread are a sin. Managing the async nature of the Gemini API within the widget's event loop required clean state management.
3.  **Visual Polish**: Getting the "native" look and feel right—using `Kirigami` components correctly so it looks like it belongs in Plasma 6—took iteration.
4.  **Layout Demons**: We hit a classic UI bug where the text input would grow infinitely or hide buttons. It turned out to be a **circular dependency** in QML anchors. Debugging this "vibe style" meant explaining the symptom to Gemini, which helped identify the logic flaw (parent sizing to child, child sizing to parent) faster than I could have traced it manually.

## 🎓 Lessons Learned/The "Vibe"
1.  **Iterate on Logic, Not Syntax**: Instead of looking up the exact QML property for a specific overlay drawer behavior, I described the *behavior* I wanted to Gemini ("Make the history pane slide out from the left and darker the background"). It nailed the implementation, allowing me to focus on the UX flow.
2.  **AI as a rubber duck**: When I hit a bug with the chat history duplication, I didn't just paste code. I explained my logic to Gemini, and it spotted the state mutation issue in `ChatStorage.js` immediately.
3.  **Documentation is Key**: The AI is only as good as the context you give it. Keeping my `README` and code comments up to date actually helped *Gemini* understand the project better in subsequent prompts.
4.  **Beyond Code**: We didn't just write code; we generated the **icon** (iterating from "flat" to "3D glassmorphism") and wrote the **release automation** together. The "Vibe" extends to the entire shipping process, not just the logic.

## 🔗 Check it out
The code is open source!
[Link to your repo here]

#KDE #Linux #OpenSource #Gemini #AI #Coding #VibeCoding #Plasma6
