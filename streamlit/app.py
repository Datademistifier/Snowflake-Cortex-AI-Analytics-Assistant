# =============================================================
# FILE: streamlit/app.py
# PURPOSE: Streamlit in Snowflake — Cortex Claims Assistant UI
# HOW TO USE:
#   1. In Snowflake UI → Streamlit → + Streamlit App
#   2. Name: cortex_claims_assistant
#   3. Database: CORTEX_DEMO  |  Schema: HEALTHCARE
#   4. Paste this entire file and click Run
# =============================================================

import streamlit as st
from snowflake.snowpark.context import get_active_session
import pandas as pd

# ── Snowflake session (auto-connects inside Snowflake) ────────
session = get_active_session()

# ── Page configuration ────────────────────────────────────────
st.set_page_config(
    page_title="Cortex Claims Assistant",
    layout="wide"
)

# ── Header ────────────────────────────────────────────────────
st.title("❄️ Snowflake Cortex AI — Healthcare Claims Assistant")
st.caption(
    "Powered by Snowflake Cortex LLM Functions (SENTIMENT · SUMMARIZE · COMPLETE) "
    "| Built by Sonal Mishra · Snowflake Squad Member · SnowPro Associate"
)
st.divider()


# ── Helper: load data with caching ───────────────────────────
@st.cache_data(ttl=300)   # cache for 5 minutes
def load_claims(status_filter: str) -> pd.DataFrame:
    base_query = "SELECT * FROM AI_ENRICHED_CLAIMS"
    if status_filter != "ALL":
        base_query += f" WHERE CLAIM_STATUS = '{status_filter}'"
    base_query += " ORDER BY CLAIM_DATE DESC"
    return session.sql(base_query).to_pandas()


@st.cache_data(ttl=300)
def load_summary_stats() -> pd.DataFrame:
    query = """
        SELECT
            CLAIM_STATUS,
            COUNT(*)             AS TOTAL_CLAIMS,
            SUM(CLAIM_AMOUNT)    AS TOTAL_AMOUNT,
            AVG(SENTIMENT_SCORE) AS AVG_SENTIMENT
        FROM AI_ENRICHED_CLAIMS
        GROUP BY CLAIM_STATUS
        ORDER BY CLAIM_STATUS
    """
    return session.sql(query).to_pandas()


# ── Sidebar ───────────────────────────────────────────────────
st.sidebar.header("⚙️ Filters")
status_filter = st.sidebar.selectbox(
    "Claim Status",
    options=["ALL", "APPROVED", "DENIED", "PENDING"],
    index=0
)

st.sidebar.divider()
st.sidebar.markdown("**About this app**")
st.sidebar.markdown(
    "This demo uses **Snowflake Cortex** LLM functions to automatically "
    "enrich healthcare claims with AI-powered sentiment scores, clinical "
    "note summaries, and care recommendations — all computed natively "
    "inside Snowflake."
)
st.sidebar.markdown(
    "🔗 [View on GitHub](https://github.com/yourusername/snowflake-cortex-healthcare-assistant)"
)


# ── Load data ─────────────────────────────────────────────────
with st.spinner("Loading AI-enriched claims from Snowflake..."):
    df = load_claims(status_filter)
    stats_df = load_summary_stats()


# ── KPI Metrics ───────────────────────────────────────────────
st.subheader("📊 Claims Overview")

col1, col2, col3, col4, col5 = st.columns(5)

total       = len(df)
approved    = len(df[df["CLAIM_STATUS"] == "APPROVED"])
denied      = len(df[df["CLAIM_STATUS"] == "DENIED"])
pending     = len(df[df["CLAIM_STATUS"] == "PENDING"])
avg_sent    = df["SENTIMENT_SCORE"].mean() if not df.empty else 0
negative_ct = len(df[df["SENTIMENT_LABEL"] == "Negative"])

col1.metric("Total Claims",       total)
col2.metric("✅ Approved",         approved)
col3.metric("❌ Denied",           denied)
col4.metric("⏳ Pending",          pending)
col5.metric("Avg Sentiment",      f"{avg_sent:.2f}",
            delta=f"{negative_ct} negative",
            delta_color="inverse")

st.divider()


# ── Tabs ──────────────────────────────────────────────────────
tab1, tab2, tab3 = st.tabs([
    "🤖 AI-Enriched Claims",
    "📈 Sentiment Analysis",
    "💬 Ask Cortex"
])


# ────────────────────────────────────────────────────────────
# TAB 1: AI-Enriched Claims Table
# ────────────────────────────────────────────────────────────
with tab1:
    st.subheader("AI-Enriched Claims")
    st.markdown(
        "Each claim is automatically enriched with **sentiment scoring**, "
        "**provider note summaries**, and **AI care recommendations** "
        "— all generated by Snowflake Cortex in real time."
    )

    if df.empty:
        st.warning("No claims found for the selected filter.")
    else:
        # Color-code sentiment
        def highlight_sentiment(val):
            if val == "Positive":
                return "background-color: #d4edda; color: #155724"
            elif val == "Negative":
                return "background-color: #f8d7da; color: #721c24"
            else:
                return "background-color: #fff3cd; color: #856404"

        display_cols = [
            "CLAIM_ID", "CLAIM_DATE", "DIAGNOSIS_DESC",
            "CLAIM_AMOUNT", "CLAIM_STATUS",
            "SENTIMENT_SCORE", "SENTIMENT_LABEL",
            "NOTES_SUMMARY", "CARE_RECOMMENDATION"
        ]

        styled = df[display_cols].style.applymap(
            highlight_sentiment, subset=["SENTIMENT_LABEL"]
        ).format({"CLAIM_AMOUNT": "${:,.2f}", "SENTIMENT_SCORE": "{:.3f}"})

        st.dataframe(styled, use_container_width=True, height=400)

        # Expandable raw notes
        st.markdown("#### 🔍 View Full Provider Notes")
        selected_claim = st.selectbox(
            "Select a claim to view full notes:",
            options=df["CLAIM_ID"].tolist()
        )
        row = df[df["CLAIM_ID"] == selected_claim].iloc[0]
        col_a, col_b = st.columns(2)
        with col_a:
            st.markdown("**Original Provider Notes**")
            st.info(row["PROVIDER_NOTES"])
        with col_b:
            st.markdown("**🤖 Cortex Summary**")
            st.success(row["NOTES_SUMMARY"])
            st.markdown("**🤖 Care Recommendation**")
            st.success(row["CARE_RECOMMENDATION"])


# ────────────────────────────────────────────────────────────
# TAB 2: Sentiment Analysis
# ────────────────────────────────────────────────────────────
with tab2:
    st.subheader("Patient Feedback Sentiment Analysis")
    st.markdown(
        "Snowflake Cortex `SENTIMENT()` scores each patient's feedback "
        "from **-1.0 (very negative)** to **+1.0 (very positive)**."
    )

    if not stats_df.empty:
        col_x, col_y = st.columns(2)

        with col_x:
            st.markdown("**Sentiment by Claim Status**")
            st.dataframe(
                stats_df[["CLAIM_STATUS", "TOTAL_CLAIMS", "AVG_SENTIMENT"]]
                .style.format({"AVG_SENTIMENT": "{:.3f}"}),
                use_container_width=True
            )

        with col_y:
            st.markdown("**Sentiment Distribution**")
            sent_dist = df["SENTIMENT_LABEL"].value_counts().reset_index()
            sent_dist.columns = ["Sentiment", "Count"]
            st.dataframe(sent_dist, use_container_width=True)

    st.divider()
    st.markdown("**All Claims — Sentiment Scores**")
    sentiment_display = df[[
        "CLAIM_ID", "CLAIM_STATUS", "DIAGNOSIS_DESC",
        "SENTIMENT_SCORE", "SENTIMENT_LABEL", "PATIENT_FEEDBACK"
    ]].sort_values("SENTIMENT_SCORE")

    st.dataframe(
        sentiment_display.style.format({"SENTIMENT_SCORE": "{:.3f}"}),
        use_container_width=True
    )


# ────────────────────────────────────────────────────────────
# TAB 3: Ask Cortex (Free-text Q&A)
# ────────────────────────────────────────────────────────────
with tab3:
    st.subheader("💬 Ask Cortex About Your Claims")
    st.markdown(
        "Type a question about the claims data below. "
        "Cortex will analyze the current dataset and answer using `COMPLETE()`."
    )

    # Example questions
    st.markdown("**Example questions to try:**")
    examples = [
        "Which denied claims seem most urgent and why?",
        "Which patients seem most frustrated based on their feedback?",
        "Summarize the overall health trends in these claims.",
        "What are the most common reasons for claim denials?",
        "Which approved claims might need a follow-up soon?"
    ]
    for ex in examples:
        st.markdown(f"- *{ex}*")

    st.divider()

    user_question = st.text_area(
        "Your question:",
        placeholder="e.g. Which denied claims need urgent follow-up?",
        height=80
    )

    if st.button("🔍 Ask Cortex", type="primary"):
        if not user_question.strip():
            st.warning("Please enter a question first.")
        else:
            with st.spinner("Cortex is analyzing your claims data..."):

                # Build context from current filtered dataset
                context_df = df[[
                    "CLAIM_ID", "CLAIM_STATUS", "DIAGNOSIS_DESC",
                    "CLAIM_AMOUNT", "SENTIMENT_LABEL", "NOTES_SUMMARY"
                ]].head(10)   # limit context size

                context_str = context_df.to_string(index=False)

                prompt = f"""You are a healthcare claims analyst AI assistant.
Here is a summary of the current claims dataset:

{context_str}

Answer the following question clearly, concisely, and in plain English:
{user_question}

Be specific and reference claim IDs where relevant."""

                # Escape single quotes in prompt
                safe_prompt = prompt.replace("'", "\\'")

                try:
                    result = session.sql(
                        f"SELECT SNOWFLAKE.CORTEX.COMPLETE('mistral-large2', '{safe_prompt}') AS ANSWER"
                    ).collect()[0]["ANSWER"]

                    st.success("**Cortex Response:**")
                    st.markdown(result)

                except Exception as e:
                    st.error(f"Cortex error: {str(e)}")
                    st.markdown(
                        "💡 Tip: Make sure Cortex is enabled in your Snowflake region "
                        "and the CORTEX_USER database role is granted."
                    )

st.divider()
st.caption(
    "Built with ❄️ Snowflake Cortex · Streamlit in Snowflake · Snowpark Python  |  "
    "github.com/yourusername/snowflake-cortex-healthcare-assistant  |  "
    "Sonal Mishra · Snowflake Squad Member"
)
