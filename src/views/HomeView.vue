<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue';
import { use } from 'echarts/core';
import { CanvasRenderer } from 'echarts/renderers';
import { LineChart } from 'echarts/charts';
import {
  TitleComponent,
  TooltipComponent,
  LegendComponent,
  GridComponent,
} from 'echarts/components';
import VChart from 'vue-echarts';
import { supabase } from "@/utils/supabase";

use([
  CanvasRenderer,
  LineChart,
  TitleComponent,
  TooltipComponent,
  LegendComponent,
  GridComponent,
]);

interface StockData {
  symbol: string;
  year: number;
  month: number;
  avg_price: number;
}

const stockData = ref<StockData[]>([]);
const selectedStocks = ref<string[]>(['AAPL', 'AMZN', 'MSFT', 'GOOGL']);
const yearRange = ref({ start: 2023, end: 2024 });
const availableStocks = ['AAPL', 'AMZN', 'MSFT', 'GOOGL'];

const fetchMonthlyAvgPrice = async () => {
  const { data, error } = await supabase
      .from('monthly_avg_price')
      .select('*')
      .in('symbol', selectedStocks.value)
      .gte('year', yearRange.value.start)
      .lte('year', yearRange.value.end)
      .order('year')
      .order('month');

  if (error) {
    console.error('Error fetching monthly average price data:', error);
  } else {
    stockData.value = data as StockData[];
  }
};

const handleStockSelection = (symbol: string) => {
  if (selectedStocks.value.includes(symbol)) {
    selectedStocks.value = selectedStocks.value.filter(s => s !== symbol);
  } else {
    selectedStocks.value.push(symbol);
  }
};

const handleYearChange = (type: 'start' | 'end', event: Event) => {
  const target = event.target as HTMLInputElement;
  if (target) {
    yearRange.value[type] = parseInt(target.value);
  }
};

const chartOption = computed(() => ({
  tooltip: {
    trigger: 'axis',
    axisPointer: {
      type: 'cross'
    }
  },
  legend: {
    data: selectedStocks.value
  },
  xAxis: {
    type: 'category',
    data: Array.from(new Set(stockData.value.map(item => `${item.year}-${item.month.toString().padStart(2, '0')}`))).sort(),
    axisLabel: {
      formatter: (value: string) => {
        const [year, month] = value.split('-');
        return `${year}-${month}`;
      }
    }
  },
  yAxis: {
    type: 'value',
    name: 'Average Price',
    axisLabel: {
      formatter: '${value}'
    }
  },
  series: selectedStocks.value.map(symbol => ({
    name: symbol,
    type: 'line',
    data: stockData.value
        .filter(item => item.symbol === symbol)
        .map(item => [
          `${item.year}-${item.month.toString().padStart(2, '0')}`,
          Number(item.avg_price.toFixed(2))
        ])
  }))
}));

onMounted(fetchMonthlyAvgPrice);

// selectedStocks と yearRange の変更を監視し、変更があればデータを再取得
watch([selectedStocks, yearRange], fetchMonthlyAvgPrice, { deep: true });

</script>

<template>
  <div class="monthly-avg-price-dashboard">
    <h1>Monthly Average Stock Price Dashboard</h1>
    <div class="controls">
      <div class="stock-selector">
        <label v-for="symbol in availableStocks" :key="symbol">
          <input
              type="checkbox"
              :checked="selectedStocks.includes(symbol)"
              @change="handleStockSelection(symbol)"
          />
          {{ symbol }}
        </label>
      </div>
      <div class="year-range-selector">
        <input
            type="number"
            v-model="yearRange.start"
            @input="(event: Event) => handleYearChange('start', event)"
            min="2000"
            max="2024"
        />
        <input
            type="number"
            v-model="yearRange.end"
            @input="(event: Event) => handleYearChange('end', event)"
            min="2000"
            max="2024"
        />
      </div>
    </div>
    <v-chart class="chart" :option="chartOption" autoresize />
  </div>
</template>

<style scoped>
.monthly-avg-price-dashboard {
  font-family: Arial, sans-serif;
}
.controls {
  margin-bottom: 20px;
}
.stock-selector label {
  margin-right: 10px;
}
.year-range-selector input {
  width: 70px;
  margin-right: 10px;
}
.chart {
  height: 600px;
}
</style>
