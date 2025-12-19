#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# 🧪 LOCAL PERFORMANCE TEST
# ═══════════════════════════════════════════════════════════════════════════════
#
# Execute locally to test the orchestrator performance
#
# Usage: ./scripts/performance-test.sh [consumers] [scenario]
#
# Examples:
#   ./scripts/performance-test.sh 50
#   ./scripts/performance-test.sh 200 stress
#   ./scripts/performance-test.sh all
#
# ═══════════════════════════════════════════════════════════════════════════════

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Args
CONSUMER_COUNT=${1:-50}
SCENARIO=${2:-normal}

echo ""
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}🧪 SDK COMPATIBILITY - LOCAL PERFORMANCE TEST${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# ─────────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────────

if [ "$CONSUMER_COUNT" == "all" ]; then
  COUNTS=(10 25 50 75 100 150 200)
else
  COUNTS=($CONSUMER_COUNT)
fi

# Simulated rate limits
case $SCENARIO in
  "aggressive") RATE_REMAINING=850 ;;
  "normal")     RATE_REMAINING=600 ;;
  "conservative") RATE_REMAINING=250 ;;
  "stress")     RATE_REMAINING=100 ;;
  *)            RATE_REMAINING=600 ;;
esac

echo -e "${CYAN}Configuration:${NC}"
echo -e "  Consumers: ${COUNTS[@]}"
echo -e "  Scenario: $SCENARIO"
echo -e "  Simulated Rate Limit: $RATE_REMAINING remaining"
echo ""

# ─────────────────────────────────────────────────────────────────────────────────
# FUNCTIONS
# ─────────────────────────────────────────────────────────────────────────────────

calculate_strategy() {
  local count=$1
  local rate=$2
  
  if [ $rate -lt 300 ]; then
    echo "conservative:5:20:15"
  elif [ $count -le 30 ]; then
    echo "turbo:25:30:1"
  elif [ $count -le 75 ]; then
    echo "fast:20:40:3"
  elif [ $count -le 150 ]; then
    echo "balanced:15:50:5"
  else
    echo "safe:10:40:8"
  fi
}

generate_consumers() {
  local count=$1
  
  local critical=$((count * 10 / 100))
  local high=$((count * 20 / 100))
  local normal=$((count * 50 / 100))
  local low=$((count - critical - high - normal))
  
  echo "$critical:$high:$normal:$low"
}

estimate_time() {
  local count=$1
  local parallel=$2
  local delay=$3
  local batches=$(( (count + parallel - 1) / parallel ))
  
  # Assume 150ms average API latency
  local api_time=$((count * 150 / parallel))
  local delay_time=$((batches * delay * 1000))
  local wave_delays=$((4 * delay * 1000))  # 4 waves
  
  local total=$((api_time + delay_time + wave_delays))
  echo $total
}

run_benchmark() {
  local count=$1
  
  echo ""
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${YELLOW}📊 Testing with $count consumers${NC}"
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  
  # Time the brain analysis
  START_BRAIN=$(date +%s%3N)
  
  # Calculate strategy
  local strategy_data=$(calculate_strategy $count $RATE_REMAINING)
  IFS=':' read -r strategy parallel batch delay <<< "$strategy_data"
  
  END_BRAIN=$(date +%s%3N)
  BRAIN_TIME=$((END_BRAIN - START_BRAIN))
  
  echo ""
  echo -e "${CYAN}🧠 Brain Analysis (${BRAIN_TIME}ms):${NC}"
  echo -e "   Strategy: ${GREEN}$strategy${NC}"
  echo -e "   Max Parallel: $parallel"
  echo -e "   Batch Size: $batch"
  echo -e "   Base Delay: ${delay}s"
  
  # Generate consumer distribution
  local dist=$(generate_consumers $count)
  IFS=':' read -r critical high normal low <<< "$dist"
  
  echo ""
  echo -e "${CYAN}🌊 Wave Distribution:${NC}"
  echo -e "   🔴 Wave 1 (Critical): $critical"
  echo -e "   🟠 Wave 2 (High): $high"
  echo -e "   🟡 Wave 3 (Normal): $normal"
  echo -e "   🟢 Wave 4 (Low): $low"
  
  # Estimate execution time
  local est_time=$(estimate_time $count $parallel $delay)
  local est_seconds=$((est_time / 1000))
  local est_minutes=$(echo "scale=2; $est_seconds / 60" | bc)
  
  # Calculate throughput
  local throughput=$(echo "scale=2; $count / $est_seconds" | bc)
  
  # Calculate API usage
  local api_calls=$((count + 10))  # +10 overhead
  local rate_usage=$(echo "scale=1; $api_calls * 100 / 1000" | bc)
  
  echo ""
  echo -e "${CYAN}⚡ Performance Estimates:${NC}"
  echo -e "   Estimated Time: ${GREEN}${est_seconds}s${NC} (~${est_minutes} min)"
  echo -e "   Throughput: ${GREEN}${throughput}${NC} consumers/sec"
  echo -e "   API Calls: $api_calls"
  echo -e "   Rate Usage: ${rate_usage}%"
  
  # Assessment
  echo ""
  echo -e "${CYAN}✅ Assessment:${NC}"
  
  if (( $(echo "$rate_usage < 50" | bc -l) )) && (( $est_seconds < 300 )); then
    echo -e "   ${GREEN}🟢 EXCELLENT - Fast execution with low API usage${NC}"
  elif (( $(echo "$rate_usage < 80" | bc -l) )) && (( $est_seconds < 600 )); then
    echo -e "   ${YELLOW}🟡 GOOD - Acceptable performance${NC}"
  else
    echo -e "   ${RED}🟠 ACCEPTABLE - Consider optimization${NC}"
  fi
  
  # Return values for summary
  echo "$count:$strategy:$est_seconds:$throughput:$rate_usage"
}

# ─────────────────────────────────────────────────────────────────────────────────
# RUN BENCHMARKS
# ─────────────────────────────────────────────────────────────────────────────────

RESULTS=()

for count in "${COUNTS[@]}"; do
  result=$(run_benchmark $count | tail -1)
  RESULTS+=("$result")
done

# ─────────────────────────────────────────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────────────────────────────────────────

echo ""
echo ""
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}📊 SUMMARY${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

printf "${CYAN}%-12s %-15s %-12s %-15s %-12s${NC}\n" "Consumers" "Strategy" "Est. Time" "Throughput" "Rate Usage"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for result in "${RESULTS[@]}"; do
  if [[ $result == *":"* ]]; then
    IFS=':' read -r count strategy time throughput rate <<< "$result"
    printf "%-12s %-15s %-12s %-15s %-12s\n" "$count" "$strategy" "${time}s" "${throughput}/s" "${rate}%"
  fi
done

echo ""
echo -e "${GREEN}✅ All benchmarks complete!${NC}"
echo ""

# ─────────────────────────────────────────────────────────────────────────────────
# RECOMMENDATIONS
# ─────────────────────────────────────────────────────────────────────────────────

echo -e "${CYAN}🎯 Recommendations:${NC}"
echo ""
echo "  • For high-priority releases: Use 'aggressive' scenario"
echo "  • For normal releases: Use 'normal' scenario (default)"
echo "  • During rate limit pressure: Use 'conservative' scenario"
echo "  • For testing: Use 'stress' scenario"
echo ""
echo -e "${BLUE}Run with different scenarios:${NC}"
echo "  ./scripts/performance-test.sh 100 aggressive"
echo "  ./scripts/performance-test.sh 200 conservative"
echo "  ./scripts/performance-test.sh all stress"
echo ""
