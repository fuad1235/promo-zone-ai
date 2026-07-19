<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="Promo Zone AI turns rough campaign ideas into creator-ready briefs and coaches drafts against real campaign requirements.">
    <meta name="theme-color" content="#0057ff">
    <meta property="og:title" content="Promo Zone AI">
    <meta property="og:description" content="Campaign clarity for brands. Better first drafts for creators. Human-controlled approvals and payouts.">
    <meta property="og:type" content="website">
    <meta property="og:url" content="https://promozone.boldtechai.com">
    <title>Promo Zone AI — Campaign clarity, built into the workflow</title>
    <style>
        :root {
            color-scheme: light;
            --blue: #0057ff;
            --blue-dark: #003fc2;
            --orange: #ff5e2b;
            --ink: #0b1220;
            --muted: #536078;
            --line: #dbe4f2;
            --wash: #f4f7ff;
            --white: #ffffff;
            --success: #0f9f6e;
            --shadow: 0 24px 70px rgba(17, 37, 75, .13);
        }

        * {
            box-sizing: border-box;
        }

        html {
            scroll-behavior: smooth;
        }

        body {
            margin: 0;
            overflow-x: hidden;
            background:
                radial-gradient(circle at 85% 8%, rgba(0, 87, 255, .11), transparent 30rem),
                radial-gradient(circle at 4% 38%, rgba(255, 94, 43, .08), transparent 24rem),
                var(--wash);
            color: var(--ink);
            font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            line-height: 1.6;
            -webkit-font-smoothing: antialiased;
        }

        a {
            color: inherit;
        }

        button,
        a {
            -webkit-tap-highlight-color: transparent;
        }

        .shell {
            width: min(1160px, calc(100% - 40px));
            margin: 0 auto;
        }

        .nav {
            min-height: 78px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 28px;
        }

        .brand {
            display: inline-flex;
            align-items: center;
            gap: 11px;
            color: var(--ink);
            text-decoration: none;
            font-weight: 850;
            letter-spacing: -.025em;
        }

        .brand-mark {
            width: 38px;
            height: 38px;
            display: grid;
            place-items: center;
            border-radius: 13px;
            background: var(--blue);
            box-shadow: 0 8px 22px rgba(0, 87, 255, .28);
            color: white;
        }

        .brand-mark svg {
            width: 22px;
            height: 22px;
        }

        .brand-name {
            font-size: 18px;
        }

        .brand-name span {
            color: var(--blue);
        }

        .nav-links {
            display: flex;
            align-items: center;
            gap: 26px;
            color: #344056;
            font-size: 14px;
            font-weight: 700;
        }

        .nav-links a {
            text-decoration: none;
        }

        .nav-links a:hover {
            color: var(--blue);
        }

        .nav-download {
            padding: 10px 16px;
            border: 1px solid #c9d7ec;
            border-radius: 12px;
            background: rgba(255, 255, 255, .76);
        }

        .hero {
            min-height: 650px;
            display: grid;
            grid-template-columns: minmax(0, 1.08fr) minmax(360px, .92fr);
            align-items: center;
            gap: clamp(48px, 8vw, 100px);
            padding: 68px 0 82px;
        }

        .eyebrow {
            display: inline-flex;
            align-items: center;
            gap: 9px;
            margin-bottom: 22px;
            padding: 7px 12px;
            border: 1px solid #cddcf5;
            border-radius: 999px;
            background: rgba(255, 255, 255, .76);
            color: #29416b;
            font-size: 12px;
            font-weight: 800;
            letter-spacing: .07em;
            text-transform: uppercase;
        }

        .eyebrow-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background: var(--orange);
            box-shadow: 0 0 0 5px rgba(255, 94, 43, .12);
        }

        h1,
        h2,
        h3,
        p {
            margin-top: 0;
        }

        h1 {
            max-width: 720px;
            margin-bottom: 22px;
            font-size: clamp(46px, 6.2vw, 76px);
            line-height: 1.01;
            letter-spacing: -.058em;
            font-weight: 880;
        }

        .gradient-word {
            color: var(--blue);
            background: linear-gradient(110deg, var(--blue), #663cff 65%, var(--orange));
            -webkit-background-clip: text;
            background-clip: text;
            -webkit-text-fill-color: transparent;
        }

        .hero-copy > p {
            max-width: 650px;
            margin-bottom: 30px;
            color: var(--muted);
            font-size: clamp(17px, 2vw, 20px);
            line-height: 1.65;
        }

        .actions {
            display: flex;
            flex-wrap: wrap;
            gap: 12px;
            margin-bottom: 28px;
        }

        .button {
            min-height: 52px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
            padding: 0 20px;
            border: 1px solid transparent;
            border-radius: 14px;
            text-decoration: none;
            font-size: 14px;
            font-weight: 800;
            transition: transform .18s ease, box-shadow .18s ease, background .18s ease;
        }

        .button:hover {
            transform: translateY(-2px);
        }

        .button-primary {
            background: var(--blue);
            color: white;
            box-shadow: 0 13px 28px rgba(0, 87, 255, .24);
        }

        .button-primary:hover {
            background: var(--blue-dark);
            box-shadow: 0 16px 34px rgba(0, 87, 255, .3);
        }

        .button-secondary {
            border-color: #ccd8e9;
            background: rgba(255, 255, 255, .78);
            color: var(--ink);
        }

        .button svg {
            width: 18px;
            height: 18px;
        }

        .proof-row {
            display: flex;
            flex-wrap: wrap;
            gap: 9px 18px;
            color: #536078;
            font-size: 13px;
            font-weight: 650;
        }

        .proof-item {
            display: inline-flex;
            align-items: center;
            gap: 7px;
        }

        .check {
            width: 18px;
            height: 18px;
            display: grid;
            place-items: center;
            border-radius: 50%;
            background: #e2f8ef;
            color: var(--success);
            font-size: 11px;
            font-weight: 900;
        }

        .product-stage {
            position: relative;
            display: grid;
            place-items: center;
        }

        .product-stage::before {
            content: "";
            position: absolute;
            inset: 12% -6% 8%;
            border-radius: 50%;
            background: linear-gradient(135deg, rgba(0, 87, 255, .18), rgba(255, 94, 43, .14));
            filter: blur(26px);
        }

        .phone {
            position: relative;
            width: min(100%, 388px);
            padding: 11px;
            border: 1px solid rgba(11, 18, 32, .16);
            border-radius: 40px;
            background: #0b1220;
            box-shadow: var(--shadow);
            transform: rotate(1.3deg);
        }

        .phone-screen {
            min-height: 580px;
            overflow: hidden;
            border-radius: 31px;
            background: #f7f9fe;
        }

        .phone-status {
            height: 28px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 0 22px;
            color: #2d3748;
            font-size: 9px;
            font-weight: 800;
        }

        .phone-content {
            padding: 12px 19px 20px;
        }

        .mini-nav {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 22px;
        }

        .mini-logo {
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 12px;
            font-weight: 850;
        }

        .mini-logo-box {
            width: 26px;
            height: 26px;
            display: grid;
            place-items: center;
            border-radius: 9px;
            background: var(--blue);
            color: white;
            font-size: 10px;
        }

        .mini-avatar {
            width: 28px;
            height: 28px;
            display: grid;
            place-items: center;
            border-radius: 50%;
            background: #ffe9df;
            color: #a73714;
            font-size: 10px;
            font-weight: 850;
        }

        .mini-kicker {
            margin-bottom: 5px;
            color: var(--blue);
            font-size: 9px;
            font-weight: 850;
            letter-spacing: .08em;
            text-transform: uppercase;
        }

        .phone h3 {
            margin-bottom: 6px;
            font-size: 21px;
            line-height: 1.15;
            letter-spacing: -.035em;
        }

        .mini-description {
            margin-bottom: 16px;
            color: #69758a;
            font-size: 10px;
            line-height: 1.5;
        }

        .ai-card {
            margin-bottom: 11px;
            padding: 15px;
            border: 1px solid #d9e3f2;
            border-radius: 18px;
            background: white;
            box-shadow: 0 9px 24px rgba(37, 56, 91, .06);
        }

        .ai-card-top {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 10px;
            margin-bottom: 11px;
        }

        .ai-chip {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            padding: 5px 8px;
            border-radius: 999px;
            background: #e8efff;
            color: var(--blue);
            font-size: 8px;
            font-weight: 850;
        }

        .ai-status {
            color: var(--success);
            font-size: 8px;
            font-weight: 850;
        }

        .brief-title {
            margin-bottom: 5px;
            font-size: 13px;
            font-weight: 850;
        }

        .brief-text {
            margin-bottom: 11px;
            color: #667187;
            font-size: 9px;
            line-height: 1.5;
        }

        .tag-row {
            display: flex;
            flex-wrap: wrap;
            gap: 5px;
        }

        .tag {
            padding: 4px 7px;
            border-radius: 7px;
            background: #f2f5fa;
            color: #536078;
            font-size: 7px;
            font-weight: 750;
        }

        .angle-list {
            display: grid;
            gap: 7px;
        }

        .angle {
            display: grid;
            grid-template-columns: 24px 1fr;
            align-items: center;
            gap: 9px;
            padding: 9px;
            border-radius: 12px;
            background: #f7f9fd;
        }

        .angle-number {
            width: 24px;
            height: 24px;
            display: grid;
            place-items: center;
            border-radius: 8px;
            background: white;
            color: var(--orange);
            font-size: 8px;
            font-weight: 900;
            box-shadow: 0 3px 9px rgba(17, 37, 75, .08);
        }

        .angle strong,
        .angle span {
            display: block;
        }

        .angle strong {
            font-size: 8px;
        }

        .angle span {
            color: #738097;
            font-size: 7px;
        }

        .human-note {
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 11px;
            border: 1px solid #ffe0d4;
            border-radius: 13px;
            background: #fff7f3;
            color: #74412f;
            font-size: 8px;
            font-weight: 700;
        }

        .human-note-icon {
            width: 22px;
            height: 22px;
            flex: 0 0 auto;
            display: grid;
            place-items: center;
            border-radius: 7px;
            background: var(--orange);
            color: white;
        }

        .stats {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            border: 1px solid var(--line);
            border-radius: 24px;
            background: rgba(255, 255, 255, .8);
            box-shadow: 0 15px 45px rgba(17, 37, 75, .06);
        }

        .stat {
            min-height: 118px;
            display: flex;
            flex-direction: column;
            justify-content: center;
            padding: 22px 28px;
        }

        .stat + .stat {
            border-left: 1px solid var(--line);
        }

        .stat-value {
            margin-bottom: 3px;
            font-size: 26px;
            font-weight: 880;
            letter-spacing: -.04em;
        }

        .stat-label {
            color: var(--muted);
            font-size: 12px;
            font-weight: 680;
        }

        .live-value {
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }

        .live-dot {
            width: 10px;
            height: 10px;
            border-radius: 50%;
            background: #94a3b8;
            box-shadow: 0 0 0 5px rgba(148, 163, 184, .14);
        }

        .live-dot.ready {
            background: var(--success);
            box-shadow: 0 0 0 5px rgba(15, 159, 110, .14);
        }

        section {
            padding: 108px 0;
        }

        .section-heading {
            max-width: 700px;
            margin-bottom: 44px;
        }

        .section-heading.centered {
            margin-right: auto;
            margin-left: auto;
            text-align: center;
        }

        .section-label {
            margin-bottom: 10px;
            color: var(--blue);
            font-size: 12px;
            font-weight: 850;
            letter-spacing: .09em;
            text-transform: uppercase;
        }

        h2 {
            margin-bottom: 16px;
            font-size: clamp(35px, 4.8vw, 54px);
            line-height: 1.08;
            letter-spacing: -.048em;
            font-weight: 860;
        }

        .section-heading p {
            margin-bottom: 0;
            color: var(--muted);
            font-size: 17px;
        }

        .feature-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 22px;
        }

        .feature-card {
            position: relative;
            overflow: hidden;
            min-height: 410px;
            padding: 36px;
            border: 1px solid var(--line);
            border-radius: 28px;
            background: white;
            box-shadow: 0 18px 55px rgba(17, 37, 75, .07);
        }

        .feature-card::after {
            content: "";
            position: absolute;
            width: 230px;
            height: 230px;
            right: -75px;
            bottom: -105px;
            border-radius: 50%;
            background: rgba(0, 87, 255, .08);
        }

        .feature-card.orange::after {
            background: rgba(255, 94, 43, .1);
        }

        .feature-icon {
            width: 50px;
            height: 50px;
            display: grid;
            place-items: center;
            margin-bottom: 28px;
            border-radius: 16px;
            background: #e7efff;
            color: var(--blue);
        }

        .feature-card.orange .feature-icon {
            background: #fff0ea;
            color: var(--orange);
        }

        .feature-icon svg {
            width: 25px;
            height: 25px;
        }

        .feature-role {
            margin-bottom: 8px;
            color: var(--muted);
            font-size: 11px;
            font-weight: 850;
            letter-spacing: .08em;
            text-transform: uppercase;
        }

        .feature-card h3 {
            margin-bottom: 13px;
            font-size: 28px;
            line-height: 1.16;
            letter-spacing: -.035em;
        }

        .feature-card > p {
            margin-bottom: 24px;
            color: var(--muted);
        }

        .feature-list {
            position: relative;
            z-index: 1;
            display: grid;
            gap: 10px;
            margin: 0;
            padding: 0;
            list-style: none;
            font-size: 13px;
            font-weight: 680;
        }

        .feature-list li {
            display: flex;
            align-items: flex-start;
            gap: 9px;
        }

        .feature-list .check {
            margin-top: 1px;
            flex: 0 0 auto;
        }

        .workflow {
            background: var(--ink);
            color: white;
        }

        .workflow .section-label {
            color: #83a8ff;
        }

        .workflow .section-heading p {
            color: #aebbd0;
        }

        .steps {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 16px;
        }

        .step {
            min-height: 250px;
            padding: 28px;
            border: 1px solid rgba(255, 255, 255, .12);
            border-radius: 24px;
            background: rgba(255, 255, 255, .055);
        }

        .step-number {
            width: 38px;
            height: 38px;
            display: grid;
            place-items: center;
            margin-bottom: 34px;
            border: 1px solid rgba(255, 255, 255, .18);
            border-radius: 12px;
            background: rgba(255, 255, 255, .08);
            color: #9bb9ff;
            font-size: 13px;
            font-weight: 900;
        }

        .step h3 {
            margin-bottom: 10px;
            font-size: 20px;
        }

        .step p {
            margin-bottom: 0;
            color: #aebbd0;
            font-size: 14px;
        }

        .safety-wrap {
            display: grid;
            grid-template-columns: .84fr 1.16fr;
            align-items: center;
            gap: clamp(40px, 8vw, 100px);
        }

        .safety-panel {
            padding: 34px;
            border: 1px solid var(--line);
            border-radius: 28px;
            background: white;
            box-shadow: var(--shadow);
        }

        .safety-item {
            display: grid;
            grid-template-columns: 38px 1fr;
            gap: 14px;
            padding: 18px 0;
        }

        .safety-item + .safety-item {
            border-top: 1px solid var(--line);
        }

        .safety-icon {
            width: 38px;
            height: 38px;
            display: grid;
            place-items: center;
            border-radius: 12px;
            background: #edf3ff;
            color: var(--blue);
            font-weight: 900;
        }

        .safety-item strong,
        .safety-item span {
            display: block;
        }

        .safety-item strong {
            margin-bottom: 3px;
            font-size: 14px;
        }

        .safety-item span {
            color: var(--muted);
            font-size: 12px;
        }

        .demo {
            padding-top: 0;
        }

        .demo-card {
            position: relative;
            overflow: hidden;
            display: grid;
            grid-template-columns: 1fr .86fr;
            gap: 50px;
            padding: clamp(34px, 6vw, 68px);
            border-radius: 32px;
            background: linear-gradient(135deg, #0057ff 0%, #1746c9 65%, #422eae 100%);
            color: white;
            box-shadow: 0 28px 80px rgba(0, 63, 194, .24);
        }

        .demo-card::after {
            content: "";
            position: absolute;
            width: 340px;
            height: 340px;
            right: -130px;
            top: -160px;
            border: 60px solid rgba(255, 255, 255, .08);
            border-radius: 50%;
        }

        .demo-card h2 {
            max-width: 620px;
            margin-bottom: 16px;
        }

        .demo-card p {
            max-width: 650px;
            margin-bottom: 27px;
            color: #d9e5ff;
        }

        .demo-card .button-primary {
            background: white;
            color: var(--blue-dark);
            box-shadow: none;
        }

        .demo-card .button-secondary {
            border-color: rgba(255, 255, 255, .3);
            background: rgba(255, 255, 255, .1);
            color: white;
        }

        .accounts {
            position: relative;
            z-index: 1;
            display: grid;
            gap: 10px;
            align-content: center;
        }

        .account {
            padding: 15px 17px;
            border: 1px solid rgba(255, 255, 255, .18);
            border-radius: 15px;
            background: rgba(255, 255, 255, .09);
            backdrop-filter: blur(8px);
        }

        .account-label {
            margin-bottom: 3px;
            color: #bcd0ff;
            font-size: 9px;
            font-weight: 850;
            letter-spacing: .08em;
            text-transform: uppercase;
        }

        .account-value {
            overflow-wrap: anywhere;
            font-size: 13px;
            font-weight: 760;
        }

        .footer {
            padding: 35px 0 44px;
            border-top: 1px solid var(--line);
        }

        .footer-inner {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 24px;
            color: var(--muted);
            font-size: 12px;
        }

        .footer-links {
            display: flex;
            flex-wrap: wrap;
            gap: 18px;
        }

        .footer-links a {
            font-weight: 750;
            text-decoration: none;
        }

        .footer-links a:hover {
            color: var(--blue);
        }

        @media (max-width: 900px) {
            .hero {
                grid-template-columns: 1fr;
                padding-top: 48px;
            }

            .hero-copy {
                text-align: center;
            }

            .hero-copy > p,
            h1 {
                margin-right: auto;
                margin-left: auto;
            }

            .actions,
            .proof-row {
                justify-content: center;
            }

            .product-stage {
                margin-top: 16px;
            }

            .stats {
                grid-template-columns: 1fr 1fr;
            }

            .stat:nth-child(3) {
                border-left: 0;
            }

            .stat:nth-child(n + 3) {
                border-top: 1px solid var(--line);
            }

            .feature-grid,
            .safety-wrap,
            .demo-card {
                grid-template-columns: 1fr;
            }

            .steps {
                grid-template-columns: 1fr;
            }

            .step {
                min-height: 0;
            }

            .step-number {
                margin-bottom: 22px;
            }
        }

        @media (max-width: 680px) {
            .shell {
                width: min(100% - 26px, 1160px);
            }

            .nav {
                min-height: 68px;
            }

            .nav-links a:not(.nav-download) {
                display: none;
            }

            .brand-name {
                font-size: 16px;
            }

            .hero {
                padding: 42px 0 64px;
            }

            h1 {
                font-size: clamp(43px, 13vw, 62px);
            }

            .button {
                width: 100%;
            }

            .proof-row {
                display: grid;
                justify-content: start;
                max-width: 330px;
                margin: 0 auto;
                text-align: left;
            }

            .phone {
                width: min(92%, 380px);
            }

            .stats {
                grid-template-columns: 1fr;
            }

            .stat + .stat,
            .stat:nth-child(3) {
                border-top: 1px solid var(--line);
                border-left: 0;
            }

            section {
                padding: 78px 0;
            }

            .feature-card,
            .safety-panel {
                padding: 26px;
            }

            .demo-card {
                gap: 32px;
            }

            .footer-inner {
                align-items: flex-start;
                flex-direction: column;
            }
        }

        @media (prefers-reduced-motion: reduce) {
            html {
                scroll-behavior: auto;
            }

            *,
            *::before,
            *::after {
                transition-duration: .01ms !important;
            }
        }
    </style>
</head>
<body>
    <header class="shell">
        <nav class="nav" aria-label="Main navigation">
            <a class="brand" href="/" aria-label="Promo Zone AI home">
                <span class="brand-mark" aria-hidden="true">
                    <svg viewBox="0 0 24 24" fill="none">
                        <path d="M7 5.5h5.6a3.4 3.4 0 0 1 0 6.8H7V5.5Z" stroke="currentColor" stroke-width="2.1" stroke-linejoin="round"/>
                        <path d="M7 12.3V19" stroke="currentColor" stroke-width="2.1" stroke-linecap="round"/>
                        <path d="m15.8 15.2 1.2-2.6 1.2 2.6 2.6 1.2-2.6 1.2-1.2 2.6-1.2-2.6-2.6-1.2 2.6-1.2Z" fill="#ffb49b"/>
                    </svg>
                </span>
                <span class="brand-name">Promo Zone <span>AI</span></span>
            </a>
            <div class="nav-links">
                <a href="#features">Features</a>
                <a href="#safety">Safety</a>
                <a href="https://github.com/fuad1235/promo-zone-ai" target="_blank" rel="noopener noreferrer">GitHub</a>
                <a class="nav-download" href="https://github.com/fuad1235/promo-zone-ai/releases/download/v1.0.0-build-week/Promo-Zone-AI-Android-e84350e.apk">Get Android app</a>
            </div>
        </nav>
    </header>

    <main>
        <div class="shell hero">
            <div class="hero-copy">
                <div class="eyebrow">
                    <span class="eyebrow-dot" aria-hidden="true"></span>
                    OpenAI Build Week 2026 · Work &amp; Productivity
                </div>
                <h1>Campaign clarity, <span class="gradient-word">built into the work.</span></h1>
                <p>
                    Promo Zone AI turns rough product ideas into creator-ready campaigns,
                    then coaches every draft against the real brief—while people keep
                    control of publishing, approvals, and payouts.
                </p>
                <div class="actions">
                    <a class="button button-primary" href="https://github.com/fuad1235/promo-zone-ai/releases/download/v1.0.0-build-week/Promo-Zone-AI-Android-e84350e.apk">
                        <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
                            <path d="M12 3v12m0 0 4.5-4.5M12 15l-4.5-4.5M5 20h14" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                        </svg>
                        Download Android APK
                    </a>
                    <a class="button button-secondary" href="https://github.com/fuad1235/promo-zone-ai" target="_blank" rel="noopener noreferrer">
                        Explore the source
                        <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
                            <path d="M7 17 17 7M8 7h9v9" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                        </svg>
                    </a>
                </div>
                <div class="proof-row" aria-label="Product highlights">
                    <span class="proof-item"><span class="check">✓</span> GPT-5.6 structured output</span>
                    <span class="proof-item"><span class="check">✓</span> Real campaign context</span>
                    <span class="proof-item"><span class="check">✓</span> Human-controlled decisions</span>
                </div>
            </div>

            <div class="product-stage" aria-label="Campaign Architect product preview">
                <div class="phone">
                    <div class="phone-screen">
                        <div class="phone-status">
                            <span>9:41</span>
                            <span>● ● ◒</span>
                        </div>
                        <div class="phone-content">
                            <div class="mini-nav">
                                <div class="mini-logo">
                                    <span class="mini-logo-box">PZ</span>
                                    Promo Zone AI
                                </div>
                                <span class="mini-avatar">SB</span>
                            </div>
                            <div class="mini-kicker">Campaign Architect</div>
                            <h3>Build a brief creators can actually use.</h3>
                            <p class="mini-description">GPT-5.6 transforms your goals and product facts into an editable campaign.</p>

                            <div class="ai-card">
                                <div class="ai-card-top">
                                    <span class="ai-chip">✦ Generated with GPT-5.6</span>
                                    <span class="ai-status">Ready to review</span>
                                </div>
                                <div class="brief-title">Mango Rush: Campus Energy</div>
                                <p class="brief-text">Show an authentic study-to-social reset with a clear first-sip product moment.</p>
                                <div class="tag-row">
                                    <span class="tag">#MangoRush</span>
                                    <span class="tag">TikTok</span>
                                    <span class="tag">@sparkbrewgh</span>
                                </div>
                            </div>

                            <div class="ai-card">
                                <div class="ai-card-top">
                                    <strong style="font-size:10px;">Content angles</strong>
                                    <span style="font-size:8px;color:#738097;">3 options</span>
                                </div>
                                <div class="angle-list">
                                    <div class="angle">
                                        <span class="angle-number">01</span>
                                        <span><strong>The 3PM reset</strong><span>Study desk to fresh energy</span></span>
                                    </div>
                                    <div class="angle">
                                        <span class="angle-number">02</span>
                                        <span><strong>First-sip check</strong><span>Honest creator reaction</span></span>
                                    </div>
                                    <div class="angle">
                                        <span class="angle-number">03</span>
                                        <span><strong>Day-in-the-life</strong><span>Product in a real routine</span></span>
                                    </div>
                                </div>
                            </div>

                            <div class="human-note">
                                <span class="human-note-icon">✓</span>
                                You review and edit every field before publishing.
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="shell stats" aria-label="Verification summary">
            <div class="stat">
                <span class="stat-value">2</span>
                <span class="stat-label">contextual AI workflows</span>
            </div>
            <div class="stat">
                <span class="stat-value">15</span>
                <span class="stat-label">passing Laravel tests</span>
            </div>
            <div class="stat">
                <span class="stat-value">7</span>
                <span class="stat-label">passing Flutter tests</span>
            </div>
            <div class="stat">
                <span class="stat-value live-value"><span class="live-dot" id="live-dot"></span><span id="live-value">Checking</span></span>
                <span class="stat-label" id="live-label">production API status</span>
            </div>
        </div>

        <section id="features">
            <div class="shell">
                <div class="section-heading centered">
                    <div class="section-label">Two sides, one clearer workflow</div>
                    <h2>Useful AI where campaign work already happens.</h2>
                    <p>Not another generic chat box. Each experience uses authenticated product context and returns structured, actionable UI.</p>
                </div>

                <div class="feature-grid">
                    <article class="feature-card">
                        <div class="feature-icon" aria-hidden="true">
                            <svg viewBox="0 0 24 24" fill="none">
                                <path d="M4 5.5A2.5 2.5 0 0 1 6.5 3h8A2.5 2.5 0 0 1 17 5.5v13a2.5 2.5 0 0 1-2.5 2.5h-8A2.5 2.5 0 0 1 4 18.5v-13Z" stroke="currentColor" stroke-width="1.8"/>
                                <path d="M8 8h5M8 12h5M8 16h3" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
                                <path d="m18.5 8 .8 1.7L21 10.5l-1.7.8-.8 1.7-.8-1.7-1.7-.8 1.7-.8.8-1.7Z" fill="currentColor"/>
                            </svg>
                        </div>
                        <div class="feature-role">For businesses</div>
                        <h3>Campaign Architect</h3>
                        <p>Turn product context, audience, tone, and campaign goals into an editable brief that creators can execute without a clarification call.</p>
                        <ul class="feature-list">
                            <li><span class="check">✓</span> Guardrails, hashtags, and ideal creator profile</li>
                            <li><span class="check">✓</span> Three genuinely different content angles</li>
                            <li><span class="check">✓</span> Payout and targeting values preserved exactly</li>
                        </ul>
                    </article>

                    <article class="feature-card orange">
                        <div class="feature-icon" aria-hidden="true">
                            <svg viewBox="0 0 24 24" fill="none">
                                <path d="M4 12a8 8 0 1 1 16 0 8 8 0 0 1-16 0Z" stroke="currentColor" stroke-width="1.8"/>
                                <path d="m8.2 12.4 2.3 2.3 5.4-5.4" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"/>
                                <path d="M12 4V2M20 12h2M12 20v2M4 12H2" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/>
                            </svg>
                        </div>
                        <div class="feature-role">For creators</div>
                        <h3>Creator Coach</h3>
                        <p>Review a hook, caption, or script against the selected live campaign and the creator’s relevant profile before filming begins.</p>
                        <ul class="feature-list">
                            <li><span class="check">✓</span> Requirement-by-requirement campaign checklist</li>
                            <li><span class="check">✓</span> Missing mentions and risky claims highlighted</li>
                            <li><span class="check">✓</span> Revised hook, draft, and practical shot list</li>
                        </ul>
                    </article>
                </div>
            </div>
        </section>

        <section class="workflow">
            <div class="shell">
                <div class="section-heading">
                    <div class="section-label">From idea to approved work</div>
                    <h2>AI assists. People decide.</h2>
                    <p>Promo Zone AI accelerates the parts that benefit from reasoning and keeps model output away from authorization and financial state.</p>
                </div>

                <div class="steps">
                    <article class="step">
                        <div class="step-number">01</div>
                        <h3>Create with context</h3>
                        <p>GPT-5.6 works from real product, campaign, and creator context—not a disconnected prompt.</p>
                    </article>
                    <article class="step">
                        <div class="step-number">02</div>
                        <h3>Review structured output</h3>
                        <p>Strict JSON-schema responses become editable product fields, checklists, and practical next actions.</p>
                    </article>
                    <article class="step">
                        <div class="step-number">03</div>
                        <h3>Keep human control</h3>
                        <p>Businesses still publish campaigns, approve work, validate proof, and authorize every payout.</p>
                    </article>
                </div>
            </div>
        </section>

        <section id="safety">
            <div class="shell safety-wrap">
                <div class="section-heading">
                    <div class="section-label">Designed for trusted operations</div>
                    <h2>Helpful by design. Bounded by default.</h2>
                    <p>The model can recommend, rewrite, and explain. It cannot publish a campaign, approve a creator, or move wallet balances.</p>
                </div>

                <div class="safety-panel">
                    <div class="safety-item">
                        <span class="safety-icon">01</span>
                        <span><strong>Server-only credentials</strong><span>The OpenAI key never enters the Flutter application or downloadable APK.</span></span>
                    </div>
                    <div class="safety-item">
                        <span class="safety-icon">02</span>
                        <span><strong>Authenticated role boundaries</strong><span>Business and creator AI routes are validated, role-protected, and rate-limited.</span></span>
                    </div>
                    <div class="safety-item">
                        <span class="safety-icon">03</span>
                        <span><strong>Untrusted-input boundaries</strong><span>Campaign text, profiles, and drafts are treated as data rather than instructions.</span></span>
                    </div>
                    <div class="safety-item">
                        <span class="safety-icon">04</span>
                        <span><strong>Human financial authority</strong><span>AI output is advisory and cannot change approval, ledger, hold, refund, or payout state.</span></span>
                    </div>
                </div>
            </div>
        </section>

        <section class="demo">
            <div class="shell">
                <div class="demo-card">
                    <div>
                        <div class="section-label" style="color:#bcd0ff;">Ready to test</div>
                        <h2>Explore the complete Android experience.</h2>
                        <p>Download the direct-install APK, sign in with either demo role, and run both GPT-5.6 workflows against the live production API.</p>
                        <div class="actions" style="margin-bottom:0;">
                            <a class="button button-primary" href="https://github.com/fuad1235/promo-zone-ai/releases/download/v1.0.0-build-week/Promo-Zone-AI-Android-e84350e.apk">Download Android APK</a>
                            <a class="button button-secondary" href="https://github.com/fuad1235/promo-zone-ai/blob/main/docs/build-week/JUDGE_GUIDE.md" target="_blank" rel="noopener noreferrer">Open judge guide</a>
                        </div>
                    </div>
                    <div class="accounts" aria-label="Demo credentials">
                        <div class="account">
                            <div class="account-label">Business account</div>
                            <div class="account-value">sparkbrew@promozone.test</div>
                        </div>
                        <div class="account">
                            <div class="account-label">Creator account</div>
                            <div class="account-value">ama.creator@promozone.test</div>
                        </div>
                        <div class="account">
                            <div class="account-label">Password for both</div>
                            <div class="account-value">Password@123</div>
                        </div>
                    </div>
                </div>
            </div>
        </section>
    </main>

    <footer class="footer">
        <div class="shell footer-inner">
            <span>© 2026 Bold Technology and AI · MIT licensed</span>
            <span class="footer-links">
                <a href="/api/health">API health</a>
                <a href="/api/ready">API readiness</a>
                <a href="https://github.com/fuad1235/promo-zone-ai" target="_blank" rel="noopener noreferrer">Source code</a>
                <a href="https://github.com/fuad1235/promo-zone-ai/releases/tag/v1.0.0-build-week" target="_blank" rel="noopener noreferrer">Android release</a>
            </span>
        </div>
    </footer>

    <script>
        const liveDot = document.getElementById('live-dot');
        const liveValue = document.getElementById('live-value');
        const liveLabel = document.getElementById('live-label');

        fetch('/api/ready', { headers: { Accept: 'application/json' } })
            .then((response) => {
                if (!response.ok) throw new Error('Not ready');
                return response.json();
            })
            .then((payload) => {
                if (payload.status !== 'ready') throw new Error('Not ready');
                liveDot.classList.add('ready');
                liveValue.textContent = 'Live';
                liveLabel.textContent = 'production API ready';
            })
            .catch(() => {
                liveValue.textContent = 'Online';
                liveLabel.textContent = 'production API';
            });
    </script>
</body>
</html>
