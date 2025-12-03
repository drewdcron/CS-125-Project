import React, { useState } from 'react';
import { Form, Button, Container, Row, Col } from 'react-bootstrap';
import { gql, useMutation } from '@apollo/client';

const CREATE_EVENT = gql`
  mutation CreateEvent($name: String!, $description: String!, $date: String!, $location: String!) {
    create_event(name: $name, description: $description, date: $date, location: $location) {
      id: ID
      name: Name
      description: Description
      date: Date
      location: Location
    }
  }
`;

const CreateEventPage: React.FC = () => {
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [date, setDate] = useState('');
  const [location, setLocation] = useState('');

  const [createEvent, { data, loading, error }] = useMutation(CREATE_EVENT);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    createEvent({ variables: { name, description, date, location } });
  };

  return (
    <Container>
      <Row className="justify-content-md-center">
        <Col md={6}>
          <h1 className="my-4">Create Event</h1>
          <Form onSubmit={handleSubmit}>
            <Form.Group controlId="formEventName">
              <Form.Label>Event Name</Form.Label>
              <Form.Control
                type="text"
                placeholder="Enter event name"
                value={name}
                onChange={(e) => setName(e.target.value)}
              />
            </Form.Group>

            <Form.Group controlId="formEventDescription">
              <Form.Label>Description</Form.Label>
              <Form.Control
                as="textarea"
                rows={3}
                placeholder="Enter event description"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
              />
            </Form.Group>

            <Form.Group controlId="formEventDate">
              <Form.Label>Date</Form.Label>
              <Form.Control
                type="date"
                value={date}
                onChange={(e) => setDate(e.target.value)}
              />
            </Form.Group>

            <Form.Group controlId="formEventLocation">
              <Form.Label>Location</Form.Label>
              <Form.Control
                type="text"
                placeholder="Enter event location"
                value={location}
                onChange={(e) => setLocation(e.target.value)}
              />
            </Form.Group>

            <Button variant="primary" type="submit" className="mt-3">
              Create Event
            </Button>
          </Form>
          {loading && <p>Loading...</p>}
          {error && <p>Error :( Please try again</p>}
          {data && <p>Event created!</p>}
        </Col>
      </Row>
    </Container>
  );
};

export default CreateEventPage;