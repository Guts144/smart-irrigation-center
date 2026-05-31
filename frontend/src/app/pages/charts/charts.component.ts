import {
  AfterViewInit,
  Component,
  ElementRef,
  OnDestroy,
  OnInit,
  ViewChild,
  inject,
} from '@angular/core';
import { Chart, ChartConfiguration, registerables } from 'chart.js';
import { Subscription } from 'rxjs';
import { ApiService } from '../../core/services/api.service';
import { SensorStreamService } from '../../core/services/sensor-stream.service';
import { SensorReading } from '../../core/models';

Chart.register(...registerables);

const MAX_POINTS = 100;
const CHART_LINE = '#ff6d00';

function formatTime(iso: string): string {
  const d = new Date(iso);
  return d.toLocaleTimeString(undefined, {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false,
  });
}

function buildOptions(yLabel: string, suggestedMax: number): ChartConfiguration<'line'>['options'] {
  return {
    responsive: true,
    maintainAspectRatio: false,
    animation: false,
    plugins: {
      legend: {
        display: true,
        labels: { color: '#2E7D32', font: { weight: 'bold', size: 13 } },
      },
    },
    scales: {
      x: {
        title: { display: true, text: 'Timeline', color: '#616161', font: { weight: 'bold' } },
        ticks: { maxTicksLimit: 10, color: '#757575' },
        grid: { color: 'rgba(102, 187, 106, 0.15)' },
      },
      y: {
        title: { display: true, text: yLabel, color: '#616161', font: { weight: 'bold' } },
        suggestedMin: 0,
        suggestedMax,
        ticks: { color: '#757575' },
        grid: { color: 'rgba(102, 187, 106, 0.15)' },
      },
    },
  };
}

function buildConfig(label: string, yLabel: string, suggestedMax: number): ChartConfiguration<'line'> {
  return {
    type: 'line',
    data: {
      labels: [],
      datasets: [{
        label,
        data: [],
        borderColor: CHART_LINE,
        backgroundColor: 'rgba(255, 109, 0, 0.08)',
        borderWidth: 2,
        pointRadius: 3,
        pointBackgroundColor: CHART_LINE,
        tension: 0.25,
        fill: false,
      }],
    },
    options: buildOptions(yLabel, suggestedMax),
  };
}

@Component({
  selector: 'app-charts',
  standalone: true,
  template: `
    <div class="charts-page">
      <header class="charts-header">
        <h1 class="header-label">📊 Sensor Analytics</h1>
        <p class="sub-header-label">Real-time performance metrics</p>
      </header>

      @if (error) { <div class="error-banner">{{ error }}</div> }
      @if (loading) { <div class="info-banner">Loading sensor history…</div> }
      @else if (pointCount === 0 && !error) {
        <div class="info-banner">No readings yet. Charts will fill when MQTT data arrives.</div>
      }

      <div class="charts-stack">
        <section class="chart-card">
          <h2 class="chart-title">🌡️ Temperature History</h2>
          <div class="chart-wrap"><canvas #tempCanvas></canvas></div>
        </section>

        <section class="chart-card">
          <h2 class="chart-title">💧 Humidity History</h2>
          <div class="chart-wrap"><canvas #humidityCanvas></canvas></div>
        </section>

        <section class="chart-card">
          <h2 class="chart-title">🌱 Soil Moisture History</h2>
          <div class="chart-wrap"><canvas #soilCanvas></canvas></div>
        </section>
      </div>
    </div>
  `,
  styles: [`
    :host {
      display: block;
      width: 100%;
    }

    .charts-page {
      padding: 1.25rem 1.5rem 2rem;
    }

    .charts-header {
      margin-bottom: 1rem;
    }

    .header-label {
      margin: 0;
      font-size: 1.75rem;
      font-weight: 700;
      color: #2E7D32;
    }

    .sub-header-label {
      margin: 0.35rem 0 0;
      font-size: 1rem;
      font-weight: 600;
      color: #616161;
      letter-spacing: 0.5px;
    }

    .info-banner {
      background: #e3f2fd;
      color: #1565c0;
      padding: 0.75rem 1rem;
      border-radius: 8px;
      margin-bottom: 1rem;
      font-size: 0.9rem;
    }

    .error-banner {
      background: #ffebee;
      color: #e53935;
      padding: 0.75rem 1rem;
      border-radius: 8px;
      margin-bottom: 1rem;
      font-size: 0.9rem;
    }

    .charts-stack {
      display: flex;
      flex-direction: column;
      gap: 1.25rem;
    }

    .chart-card {
      background: rgba(255, 255, 255, 0.95);
      border-radius: 15px;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
      padding: 1rem 1.15rem 1.15rem;
    }

    .chart-title {
      margin: 0 0 0.75rem;
      font-size: 1.125rem;
      font-weight: 600;
      color: #2E7D32;
    }

    .chart-wrap {
      position: relative;
      height: 280px;
      min-height: 250px;
    }
  `]
})
export class ChartsComponent implements OnInit, AfterViewInit, OnDestroy {
  @ViewChild('tempCanvas') private tempCanvas!: ElementRef<HTMLCanvasElement>;
  @ViewChild('humidityCanvas') private humidityCanvas!: ElementRef<HTMLCanvasElement>;
  @ViewChild('soilCanvas') private soilCanvas!: ElementRef<HTMLCanvasElement>;

  private readonly api = inject(ApiService);
  private readonly stream = inject(SensorStreamService);

  loading = true;
  error = '';
  pointCount = 0;

  private labels: string[] = [];
  private tempData: number[] = [];
  private humidityData: number[] = [];
  private soilData: number[] = [];
  private lastId = 0;
  private historySub?: Subscription;
  private streamSub?: Subscription;

  private tempChart?: Chart<'line'>;
  private humidityChart?: Chart<'line'>;
  private soilChart?: Chart<'line'>;

  ngOnInit(): void {
    this.stream.connect();
    this.streamSub = this.stream.onReading$.subscribe(reading => this.addReading(reading));
  }

  ngAfterViewInit(): void {
    // Defer so canvas elements have layout dimensions
    requestAnimationFrame(() => {
      try {
        this.tempChart = new Chart(this.tempCanvas.nativeElement, buildConfig('Temperature', 'Degrees (°C)', 40));
        this.humidityChart = new Chart(this.humidityCanvas.nativeElement, buildConfig('Humidity', 'Percentage (%)', 100));
        this.soilChart = new Chart(this.soilCanvas.nativeElement, buildConfig('Soil Moisture', 'Percentage (%)', 100));
        this.loadHistory();
      } catch (e) {
        this.error = 'Could not initialize charts.';
        this.loading = false;
        console.error(e);
      }
    });
  }

  ngOnDestroy(): void {
    this.historySub?.unsubscribe();
    this.streamSub?.unsubscribe();
    this.stream.disconnect();
    this.tempChart?.destroy();
    this.humidityChart?.destroy();
    this.soilChart?.destroy();
  }

  private loadHistory(): void {
    this.historySub = this.api.getRecentSensors(0, MAX_POINTS).subscribe({
      next: page => {
        const readings = [...page.content].reverse();
        for (const r of readings) {
          this.pushPoint(r, false);
          this.lastId = Math.max(this.lastId, r.id);
        }
        this.trimToMax();
        this.refreshCharts();
        this.loading = false;
      },
      error: err => {
        this.error = err.error?.detail || err.error?.message || 'Could not load sensor history.';
        this.loading = false;
      },
    });
  }

  private addReading(r: SensorReading): void {
    if (r.id <= this.lastId) return;
    this.lastId = r.id;
    this.pushPoint(r, true);
    this.refreshCharts();
  }

  private pushPoint(r: SensorReading, trim: boolean): void {
    this.labels.push(formatTime(r.recordedAt));
    this.tempData.push(r.temperature);
    this.humidityData.push(r.humidity);
    this.soilData.push(r.soilMoisture);
    this.pointCount = this.labels.length;
    if (trim) this.trimToMax();
  }

  private trimToMax(): void {
    while (this.labels.length > MAX_POINTS) {
      this.labels.shift();
      this.tempData.shift();
      this.humidityData.shift();
      this.soilData.shift();
    }
  }

  private refreshCharts(): void {
    this.updateChart(this.tempChart, this.tempData, 40);
    this.updateChart(this.humidityChart, this.humidityData, 100);
    this.updateChart(this.soilChart, this.soilData, 100);
  }

  private updateChart(chart: Chart<'line'> | undefined, values: number[], fallbackMax: number): void {
    if (!chart) return;
    chart.data.labels = [...this.labels];
    chart.data.datasets[0].data = [...values];
    const maxVal = values.length ? Math.max(...values) * 1.15 : fallbackMax;
    if (chart.options?.scales?.['y']) {
      chart.options.scales['y'].suggestedMax = Math.max(maxVal, fallbackMax * 0.25);
    }
    chart.update();
  }
}
