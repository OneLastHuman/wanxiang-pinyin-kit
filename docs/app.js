const examples = {
  jvede: {
    key: "jvede",
    old: "巨额的",
    cands: ["觉得", "觉", "巨额", "决", "绝"],
  },
  huar: {
    key: "huar",
    old: "华人",
    cands: ["花儿", "画儿", "话儿", "华二", "花"],
  },
  zhonggup: {
    key: "zhonggup",
    old: "种股票",
    cands: ["中国", "正规", "众多", "中有", "终于"],
  },
  nihap: {
    key: "nihap",
    old: "你会安排",
    cands: ["你好", "遗憾", "害怕", "安排", "含义"],
  },
};

const typed = document.getElementById("typed-text");
const strip = document.getElementById("strip");
const caption = document.getElementById("caption");
const chips = Array.from(document.querySelectorAll(".chips button"));
const copyBtn = document.getElementById("copy-btn");
const installCmd = document.getElementById("install-cmd");
const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

function render(key, animate) {
  const ex = examples[key];
  if (!ex) return;

  typed.textContent = ex.key;
  strip.replaceChildren();

  ex.cands.forEach((word, i) => {
    const item = document.createElement("li");
    item.className = "cand";
    const num = document.createElement("span");
    num.className = "num";
    num.textContent = String(i + 1);
    item.append(num, document.createTextNode(word));
    strip.append(item);
  });

  caption.textContent = `以前第一候选是「${ex.old}」，现在是「${ex.cands[0]}」。`;

  if (animate && !reduceMotion) {
    strip.classList.remove("is-swapping");
    void strip.offsetWidth;
    strip.classList.add("is-swapping");
  }
}

chips.forEach((button) => {
  button.addEventListener("click", () => {
    chips.forEach((b) => b.setAttribute("aria-pressed", String(b === button)));
    render(button.dataset.key, true);
  });
});

if (copyBtn && installCmd) {
  copyBtn.addEventListener("click", async () => {
    const text = installCmd.textContent;
    try {
      await navigator.clipboard.writeText(text);
    } catch {
      const area = document.createElement("textarea");
      area.value = text;
      area.setAttribute("readonly", "");
      area.style.position = "fixed";
      area.style.left = "-9999px";
      document.body.append(area);
      area.select();
      document.execCommand("copy");
      area.remove();
    }
    copyBtn.textContent = "已复制";
    window.setTimeout(() => {
      copyBtn.textContent = "复制";
    }, 1600);
  });
}

if (!reduceMotion) {
  const first = "jvede";
  typed.textContent = "";
  strip.style.opacity = "0";

  let i = 0;
  const timer = window.setInterval(() => {
    i += 1;
    typed.textContent = first.slice(0, i);
    if (i >= first.length) {
      window.clearInterval(timer);
      strip.style.transition = "opacity 220ms ease-out";
      strip.style.opacity = "1";
    }
  }, 105);
}
