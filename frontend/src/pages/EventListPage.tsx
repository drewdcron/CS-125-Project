import React from 'react';
import { gql, useQuery } from '@apollo/client';
import { Link } from 'react-router-dom';
import { ListGroup, Spinner, Alert, Button, Container, Row, Col } from 'react-bootstrap';

// Define the type for a single event
type Event = {
  id: string;
  name: string;
  status: string;
  date: string;
};

// GraphQL query to fetch all events
const GET_EVENTS = gql`
  query GetEvents {
    events {
      id
      name
      status
      date
    }
  }
`;

const EventListPage: React.FC = () => {
  const { loading, error, data } = useQuery(GET_EVENTS);

  if (loading) {
    return (
      <div className="text-center">
        <Spinner animation="border" role="status">
          <span className="visually-hidden">Loading...</span>
        </Spinner>
      </div>
    );
  }

  if (error) {
    return (
      <Alert variant="danger">
        <Alert.Heading>Oh snap! You got an error!</Alert.Heading>
        <p>
          Could not fetch events. Error: {error.message}
        </p>
      </Alert>
    );
  }

  return (
    <Container>
      <Row className="justify-content-md-center">
        <Col md={8}>
          <div className="d-flex justify-content-between align-items-center mb-4">
            <h1>Events</h1>
            <Link to="/events/new">
              <Button variant="primary">
                Create New Event
              </Button>
            </Link>
          </div>
          {data && data.events.length === 0 ? (
            <Alert variant="info">No events found. Create one to get started!</Alert>
          ) : (
            <ListGroup>
              {data && data.events.map((event: Event) => (
                <ListGroup.Item
                  key={event.id}
                  as={Link}
                  to={`/events/${event.id}`}
                  action
                  className="d-flex justify-content-between align-items-start event-card"
                >
                  <div className="ms-2 me-auto">
                    <div className="fw-bold">{event.name}</div>
                    <small className="text-muted">{new Date(event.date).toLocaleDateString()}</small>
                  </div>
                  <span className={`badge bg-${event.status === 'OPEN' ? 'success' : event.status === 'CLOSED' ? 'secondary' : 'warning'} rounded-pill`}>
                    {event.status}
                  </span>
                </ListGroup.Item>
              ))}
            </ListGroup>
          )}
        </Col>
      </Row>
    </Container>
  );
};

export default EventListPage;