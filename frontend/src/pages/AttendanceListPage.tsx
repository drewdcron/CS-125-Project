import React from 'react';
import { useParams } from 'react-router-dom';
import { gql, useQuery } from '@apollo/client';
import { Container, Row, Col, ListGroup } from 'react-bootstrap';

const GET_ATTENDANCE = gql`
  query GetAttendance($eventId: ID!) {
    attendance(eventId: $eventId) {
      id
      name
      checkInTime
    }
  }
`;

const AttendanceListPage: React.FC = () => {
  const { eventId } = useParams<{ eventId: string }>();
  const { data, loading, error } = useQuery(GET_ATTENDANCE, {
    variables: { eventId },
  });

  if (loading) return <p>Loading...</p>;
  if (error) return <p>Error :(</p>;

  const { attendance } = data;

  return (
    <Container>
      <Row>
        <Col>
          <h1 className="my-4">Attendance</h1>
          <ListGroup>
            {attendance.map((attendant: any) => (
              <ListGroup.Item key={attendant.id}>
                {attendant.name} - Checked in at {new Date(attendant.checkInTime).toLocaleString()}
              </ListGroup.Item>
            ))}
          </ListGroup>
        </Col>
      </Row>
    </Container>
  );
};

export default AttendanceListPage;