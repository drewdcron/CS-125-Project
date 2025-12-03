import { Routes, Route } from 'react-router-dom';

import Layout from './components/Layout';
import EventListPage from './pages/EventListPage';
import EventDetailPage from './pages/EventDetailPage';
import CreateEventPage from './pages/CreateEventPage';
import CheckInPage from './pages/CheckInPage';
import AttendanceListPage from './pages/AttendanceListPage';

function App() {
  return (
    <Routes>
      <Route path="/" element={<Layout />}>
        <Route index element={<EventListPage />} />
        <Route path="events">
          <Route path="new" element={<CreateEventPage />} />
          <Route path=":id" element={<EventDetailPage />} />
          <Route path=":id/checkin" element={<CheckInPage />} />
          <Route path=":id/attendance" element={<AttendanceListPage />} />
        </Route>
      </Route>
    </Routes>
  );
}

export default App;