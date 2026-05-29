import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';

const errorRate = new Rate('errors');
const requestDuration = new Trend('request_duration', true);

export const options = {
  stages: [
    { duration: '1m', target: 10 },
    { duration: '3m', target: 50 },
    { duration: '5m', target: 100 },
    { duration: '5m', target: 200 },
    { duration: '3m', target: 100 },
    { duration: '2m', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'],
    http_req_failed: ['rate<0.01'],
    errors: ['rate<0.01'],
  },
};

export default function () {
  const responses = http.batch([
    ['GET', `${BASE_URL}/`, null, { tags: { name: 'root' } }],
    ['GET', `${BASE_URL}/health`, null, { tags: { name: 'health' } }],
  ]);

  for (const res of responses) {
    const ok = check(res, {
      'status is 2xx': (r) => r.status >= 200 && r.status < 300,
      'response time < 500ms': (r) => r.timings.duration < 500,
    });
    errorRate.add(!ok);
    requestDuration.add(res.timings.duration);
  }

  sleep(1);
}

export function handleSummary(data) {
  return {
    'results/stress-summary.json': JSON.stringify(data, null, 2),
  };
}
