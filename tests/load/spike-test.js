import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';
const errorRate = new Rate('errors');

export const options = {
  stages: [
    { duration: '30s', target: 5 },
    { duration: '10s', target: 500 },
    { duration: '1m', target: 500 },
    { duration: '10s', target: 5 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<2000'],
    http_req_failed: ['rate<0.05'],
    errors: ['rate<0.05'],
  },
};

export default function () {
  const res = http.get(`${BASE_URL}/health`, { tags: { name: 'health-spike' } });
  const ok = check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 2s': (r) => r.timings.duration < 2000,
  });
  errorRate.add(!ok);
  sleep(0.1);
}

export function handleSummary(data) {
  return {
    'results/spike-summary.json': JSON.stringify(data, null, 2),
  };
}
