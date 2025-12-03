import React, { useState } from 'react';
import { useParams } from 'react-router-dom';
import { gql, useMutation } from '@apollo/client';
import { Form, Button, Container, Row, Col } from 'react-bootstrap';

const CHECK_IN = gql`
  mutation CheckIn($event_id: Int!, $name: String!) {
    check_in_by_name(event_id: $event_id, name: $name)
  }
`;

const CheckInPage: React.FC = () => {
  const { eventId } = useParams<{ eventId: string }>();
  const [name, setName] = useState('');
  const [checkIn, { data, loading, error }] = useMutation(CHECK_IN);
  const event_id = parseInt(eventId || '', 10);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    checkIn({ variables: { event_id, name } });
  };

  return (
    <Container>
      <Row className="justify-content-md-center">
        <Col md={6}>
          <h1 className="my-4">Check In</h1>
          <Form onSubmit={handleSubmit}>
            <Form.Group controlId="formName">
              <Form.Label>Name</Form.Label>
              <Form.Control
                type="text"
                placeholder="Enter your name"
                value={name}
                onChange={(e) => setName(e.target.value)}
              />
            </Form.Group>
            <Button variant="primary" type="submit" className="mt-3">
              Check In
            </Button>
          </Form>
          {loading && <p>Loading...</p>}
          {error && <p>Error :( Please try again</p>}
          {data && <p>Checked in!</p>}
        </Col>
      </Row>
    </Container>
  );
};

export default CheckInPage;