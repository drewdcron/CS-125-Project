import React from 'react';
import { useParams, Link } from 'react-router-dom';
import { gql, useQuery } from '@apollo/client';
import { Container, Row, Col, Card, Button } from 'react-bootstrap';

const GET_EVENT = gql`
  query GetEvent($event_id: Int!) {
    event(event_id: $event_id) {
      id: ID
      name: Name
      description: Description
      date: Date
      location: Location
    }
  }
`;

const EventDetailPage: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const eventId = parseInt(id || '', 10);
  const { data, loading, error } = useQuery(GET_EVENT, {
    variables: { event_id: eventId },
    skip: !eventId
  });

  if (loading) return <p>Loading...</p>;
  if (error) return <p>Error :(</p>;
  if (!data || !data.event) return <p>Event not found.</p>;

  const { event } = data;

  return (
    <Container>
      <Row className="my-4">
        <Col>
          <Card>
            <Card.Body>
              <Card.Title>{event.name}</Card.Title>
              <Card.Subtitle className="mb-2 text-muted">{event.date}</Card.Subtitle>
              <Card.Text>{event.description}</Card.Text>
              <Card.Text><strong>Location:</strong> {event.location}</Card.Text>
              <Link to={`/checkin/${event.id}`}>
                <Button variant="primary">Check In</Button>
              </Link>
              <Link to={`/attendance/${event.id}`} className="ms-2">
                <Button variant="secondary">View Attendance</Button>
              </Link>
            </Card.Body>
          </Card>
        </Col>
      </Row>
    </Container>
  );
};

export default EventDetailPage;